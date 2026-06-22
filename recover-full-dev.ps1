param(
  [string]$Region = "us-east-1",
  [string]$ClusterName = "blacktickets-dev",
  [string]$Namespace = "blacktickets-dev",
  [string]$TfStateBucket = "blacktickets-dev-tfstate",
  [string]$TfLockTable = "blacktickets-dev-terraform-locks",
  [string]$BackendConfig = "dev.hcl",
  [string]$VarsFile = "dev.tfvars",
  [switch]$AutoApprove,
  [switch]$SkipBootstrap,
  [switch]$SkipStateRestore,
  [switch]$SkipTerraform,
  [switch]$SkipSecrets,
  [switch]$SkipVerify
)

$ErrorActionPreference = "Stop"

$InfraRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Join-Path $InfraRoot "terraform"

function Ensure-DbPassword {
  if (-not [string]::IsNullOrWhiteSpace($env:TF_VAR_db_password)) {
    return
  }

  $secure = Read-Host "DB password for Terraform and app secret" -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $env:TF_VAR_db_password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$Script,
    [Parameter(Mandatory = $true)]
    [string]$Label
  )

  Write-Host ""
  Write-Host "==> $Label"
  & $Script
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE."
  }
}

Set-Location $InfraRoot
Ensure-DbPassword

Invoke-Checked -Label "AWS identity check" -Script {
  aws sts get-caller-identity | Out-Host
}

if (-not $SkipBootstrap) {
  Invoke-Checked -Label "Terraform backend bootstrap" -Script {
    & (Join-Path $InfraRoot "bootstrap.ps1") -Region $Region -BucketName $TfStateBucket -DynamoDbTable $TfLockTable -AutoApprove:$AutoApprove
  }
}

if (-not $SkipStateRestore) {
  try {
    Invoke-Checked -Label "Terraform state restore" -Script {
      & (Join-Path $InfraRoot "restore-state.ps1") -Region $Region -Bucket $TfStateBucket -LockTable $TfLockTable -AutoApprove:$AutoApprove
    }
  }
  catch {
    Write-Warning "State restore did not complete: $($_.Exception.Message)"
    Write-Warning "Continuing. Terraform can still rebuild from configuration if AWS resources were fully cleaned."
  }
}

if (-not $SkipTerraform) {
  Push-Location $TerraformDir
  try {
    Invoke-Checked -Label "Terraform init" -Script {
      terraform init -backend-config $BackendConfig
    }

    Invoke-Checked -Label "Terraform plan" -Script {
      terraform plan -var-file $VarsFile -out tfplan-full-recover -no-color
    }

    terraform show -no-color tfplan-full-recover > plan-full-recover.txt
    $summary = Select-String -Path plan-full-recover.txt -Pattern "^Plan:" | Select-Object -First 1
    if ($summary) {
      Write-Host $summary.Line
    }

    $danger = Select-String -Path plan-full-recover.txt -Pattern "will be destroyed|must be replaced"
    if ($danger) {
      Write-Host "Dangerous Terraform plan detected:"
      $danger | ForEach-Object { Write-Host $_.Line }
      throw "Stopping before apply. Review terraform\plan-full-recover.txt."
    }

    if ($summary -and $summary.Line -notmatch "0 to add, 0 to change, 0 to destroy") {
      Invoke-Checked -Label "Terraform apply" -Script {
        terraform apply tfplan-full-recover
      }
    } else {
      Write-Host "No Terraform changes to apply."
    }
  }
  finally {
    Pop-Location
  }
}

Invoke-Checked -Label "Update kubeconfig" -Script {
  aws eks update-kubeconfig --region $Region --name $ClusterName
}

if (-not $SkipSecrets) {
  Invoke-Checked -Label "Seed Secrets Manager" -Script {
    & (Join-Path $InfraRoot "seed-secrets.ps1") -Region $Region -VarsFile $VarsFile
  }
}

Write-Host ""
Write-Host "Triggering ArgoCD and External Secrets reconciliation..."
kubectl annotate application blacktickets -n argocd argocd.argoproj.io/refresh=hard force-sync="$(Get-Date -Format yyyyMMddHHmmss)" --overwrite
kubectl annotate externalsecret blacktickets-app-secrets -n $Namespace force-sync="$(Get-Date -Format yyyyMMddHHmmss)" --overwrite

Write-Host "Waiting for application deployments..."
foreach ($deployment in @("frontend", "identity-service", "event-service", "booking-service", "chatbot-service")) {
  kubectl rollout status "deployment/$deployment" -n $Namespace --timeout=240s
}

if (-not $SkipVerify) {
  Invoke-Checked -Label "Verify development stack" -Script {
    & (Join-Path $InfraRoot "verify-dev.ps1") -Region $Region -ClusterName $ClusterName -Namespace $Namespace
  }
}

Write-Host ""
Write-Host "Full development recovery complete."
