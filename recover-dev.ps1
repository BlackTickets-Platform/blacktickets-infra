$ErrorActionPreference = "Stop"

$InfraRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Region = "us-east-1"
$ClusterName = "blacktickets-dev"
$AppNamespace = "blacktickets-dev"
$TfStateBucket = "blacktickets-dev-tfstate"
$TfLockTable = "blacktickets-dev-terraform-locks"

Set-Location $InfraRoot

if ([string]::IsNullOrWhiteSpace($env:TF_VAR_db_password)) {
  throw "Set TF_VAR_db_password first. Example: `$env:TF_VAR_db_password = '<db password>'"
}

Write-Host "Checking AWS identity..."
aws sts get-caller-identity | Out-Host

Write-Host "Checking Terraform backend S3 bucket..."
aws s3api head-bucket --bucket $TfStateBucket 2>$null
if ($LASTEXITCODE -ne 0) {
  throw "Terraform state bucket '$TfStateBucket' is missing or inaccessible. Run bootstrap first."
}

Write-Host "Checking Terraform DynamoDB lock table..."
aws dynamodb describe-table --table-name $TfLockTable --region $Region *> $null
if ($LASTEXITCODE -ne 0) {
  throw "Terraform lock table '$TfLockTable' is missing or inaccessible. Run bootstrap first."
}

Write-Host "Running Terraform init..."
Push-Location (Join-Path $InfraRoot "terraform")
try {
  terraform init -backend-config dev.hcl
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform init -backend-config dev.hcl"
  }
}
finally {
  Pop-Location
}

Write-Host "Running Terraform plan..."
Push-Location (Join-Path $InfraRoot "terraform")
try {
  terraform plan -var-file dev.tfvars -out tfplan-recover -no-color
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform plan -var-file dev.tfvars -out tfplan-recover -no-color"
  }

  terraform show -no-color tfplan-recover > plan-recover.txt
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform show -no-color tfplan-recover"
  }
}
finally {
  Pop-Location
}

$summary = Select-String -Path terraform\plan-recover.txt -Pattern "^Plan:" | Select-Object -First 1
$danger = Select-String -Path terraform\plan-recover.txt -Pattern "will be destroyed|must be replaced"

if ($summary) {
  Write-Host $summary.Line
} else {
  Write-Host "Terraform plan has no change summary."
}

if ($danger) {
  Write-Host "Dangerous Terraform plan detected:"
  $danger | ForEach-Object { Write-Host $_.Line }
  throw "Stopping before apply. Review terraform\plan-recover.txt."
}

if ($summary -and $summary.Line -notmatch "0 to add, 0 to change, 0 to destroy") {
  Write-Host "Applying safe Terraform plan..."
  Push-Location (Join-Path $InfraRoot "terraform")
  try {
    terraform apply tfplan-recover
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed with exit code ${LASTEXITCODE}: terraform apply tfplan-recover"
    }
  }
  finally {
    Pop-Location
  }
} else {
  Write-Host "No Terraform changes to apply."
}

Write-Host "Updating kubeconfig..."
aws eks update-kubeconfig --region $Region --name $ClusterName

Write-Host "Checking EKS nodes..."
kubectl get nodes

Write-Host "Checking ArgoCD pods..."
kubectl get pods -n argocd

Write-Host "Checking application pods..."
kubectl get pods -n $AppNamespace

Write-Host "Checking ArgoCD application..."
kubectl get application blacktickets -n argocd

Write-Host "Triggering ArgoCD resync..."
kubectl annotate application blacktickets -n argocd force-sync="$(Get-Date -Format yyyyMMddHHmmss)" --overwrite

Write-Host "Checking ExternalSecret..."
kubectl get externalsecret -n $AppNamespace
kubectl annotate externalsecret blacktickets-app-secrets -n $AppNamespace force-sync="$(Get-Date -Format yyyyMMddHHmmss)" --overwrite

Write-Host "Waiting for deployments..."
$deployments = @(
  "frontend",
  "identity-service",
  "event-service",
  "booking-service",
  "chatbot-service"
)

foreach ($deployment in $deployments) {
  kubectl rollout status "deployment/$deployment" -n $AppNamespace --timeout=180s
}

Write-Host "Final pod status:"
kubectl get pods -n $AppNamespace

Write-Host "Recovery check complete."
