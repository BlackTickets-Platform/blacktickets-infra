$ErrorActionPreference = "Stop"

$InfraRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BootstrapDir = Join-Path $InfraRoot "bootstrap"

if (-not (Test-Path $BootstrapDir)) {
  throw "Bootstrap directory not found: $BootstrapDir"
}

Write-Host "Bootstrapping Terraform backend resources..."
Write-Host "Directory: $BootstrapDir"
Write-Host ""
Write-Host "This creates or verifies:"
Write-Host "- S3 bucket: blacktickets-dev-tfstate"
Write-Host "- DynamoDB table: blacktickets-dev-terraform-locks"
Write-Host ""

Push-Location $BootstrapDir
try {
  terraform init
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform init"
  }

  terraform plan -out bootstrap.tfplan -no-color
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform plan -out bootstrap.tfplan -no-color"
  }

  $answer = Read-Host "Apply bootstrap plan? Type yes to continue"
  if ($answer -ne "yes") {
    Write-Host "Bootstrap apply skipped."
    exit 0
  }

  terraform apply bootstrap.tfplan
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform apply bootstrap.tfplan"
  }
}
finally {
  Pop-Location
}

Write-Host "Verifying backend resources..."
aws s3api head-bucket --bucket blacktickets-dev-tfstate
if ($LASTEXITCODE -ne 0) {
  throw "Command failed with exit code ${LASTEXITCODE}: aws s3api head-bucket --bucket blacktickets-dev-tfstate"
}

aws dynamodb describe-table --table-name blacktickets-dev-terraform-locks --region us-east-1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Command failed with exit code ${LASTEXITCODE}: aws dynamodb describe-table --table-name blacktickets-dev-terraform-locks --region us-east-1"
}

Write-Host "Bootstrap complete."
