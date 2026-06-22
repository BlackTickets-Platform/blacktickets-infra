param(
  [string]$Region = "us-east-1",
  [string]$BucketName = "blacktickets-dev-tfstate",
  [string]$DynamoDbTable = "blacktickets-dev-terraform-locks",
  [switch]$AutoApprove
)

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
Write-Host "- S3 bucket: $BucketName"
Write-Host "- DynamoDB table: $DynamoDbTable"
Write-Host ""

Push-Location $BootstrapDir
try {
  terraform init
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform init"
  }

  terraform plan -var="region=$Region" -var="bucket_name=$BucketName" -var="dynamodb_table=$DynamoDbTable" -out bootstrap.tfplan -no-color
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform plan"
  }

  if (-not $AutoApprove) {
    $answer = Read-Host "Apply bootstrap plan? Type yes to continue"
    if ($answer -ne "yes") {
      Write-Host "Bootstrap apply skipped."
      exit 0
    }
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
aws s3api head-bucket --bucket $BucketName
if ($LASTEXITCODE -ne 0) {
  throw "Command failed with exit code ${LASTEXITCODE}: aws s3api head-bucket --bucket $BucketName"
}

aws dynamodb describe-table --table-name $DynamoDbTable --region $Region | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Command failed with exit code ${LASTEXITCODE}: aws dynamodb describe-table --table-name $DynamoDbTable --region $Region"
}

Write-Host "Bootstrap complete."
