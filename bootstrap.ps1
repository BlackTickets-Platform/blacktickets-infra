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

terraform -chdir=$BootstrapDir init
terraform -chdir=$BootstrapDir plan -out bootstrap.tfplan

$answer = Read-Host "Apply bootstrap plan? Type yes to continue"
if ($answer -ne "yes") {
  Write-Host "Bootstrap apply skipped."
  exit 0
}

terraform -chdir=$BootstrapDir apply bootstrap.tfplan

Write-Host "Verifying backend resources..."
aws s3api head-bucket --bucket blacktickets-dev-tfstate
aws dynamodb describe-table --table-name blacktickets-dev-terraform-locks --region us-east-1 *> $null

Write-Host "Bootstrap complete."
