$ErrorActionPreference = "Stop"

$InfraRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Join-Path $InfraRoot "terraform"
$BackupDir = Join-Path $InfraRoot "state-backups"

$Region = "us-east-1"
$Bucket = "blacktickets-dev-tfstate"
$Key = "blacktickets/dev/terraform.tfstate"
$LockTable = "blacktickets-dev-terraform-locks"

Set-Location $InfraRoot

if (-not (Test-Path $BackupDir)) {
  New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

Write-Host "Checking backend bucket..."
aws s3api head-bucket --bucket $Bucket 2>$null
if ($LASTEXITCODE -ne 0) {
  throw "Backend bucket '$Bucket' is missing or inaccessible. Run .\bootstrap.ps1 first."
}

Write-Host "Checking lock table..."
aws dynamodb describe-table --table-name $LockTable --region $Region *> $null
if ($LASTEXITCODE -ne 0) {
  throw "DynamoDB lock table '$LockTable' is missing or inaccessible. Run .\bootstrap.ps1 first."
}

Write-Host "Checking remote Terraform state object..."
aws s3api head-object --bucket $Bucket --key $Key --region $Region *> $null
if ($LASTEXITCODE -eq 0) {
  Write-Host "Remote state exists."

  $backupPath = Join-Path $BackupDir ("terraform-state-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".json")
  Write-Host "Pulling a local backup to $backupPath"
  terraform -chdir=$TerraformDir init -backend-config=dev.hcl
  terraform -chdir=$TerraformDir state pull > $backupPath
  Write-Host "State backup complete."
  exit 0
}

Write-Host "Remote state object is missing. Looking for previous S3 object versions..."

$versionsJson = aws s3api list-object-versions `
  --bucket $Bucket `
  --prefix $Key `
  --region $Region `
  --output json

$versions = ($versionsJson | ConvertFrom-Json).Versions |
  Where-Object { $_.Key -eq $Key -and $_.IsLatest -ne $true } |
  Sort-Object LastModified -Descending

if (-not $versions -or $versions.Count -eq 0) {
  throw "No previous S3 versions found for s3://$Bucket/$Key. State cannot be restored automatically; imports or rebuild are required."
}

$version = $versions | Select-Object -First 1
Write-Host "Found previous state version:"
Write-Host "VersionId: $($version.VersionId)"
Write-Host "LastModified: $($version.LastModified)"
Write-Host "Size: $($version.Size)"

$answer = Read-Host "Restore this version as the current Terraform state? Type yes to continue"
if ($answer -ne "yes") {
  Write-Host "State restore skipped."
  exit 0
}

$restorePath = Join-Path $BackupDir ("restored-terraform-state-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".json")

aws s3api get-object `
  --bucket $Bucket `
  --key $Key `
  --version-id $version.VersionId `
  --region $Region `
  $restorePath | Out-Null

aws s3api put-object `
  --bucket $Bucket `
  --key $Key `
  --region $Region `
  --body $restorePath `
  --content-type "application/json" | Out-Null

Write-Host "Restored state object from previous S3 version."
Write-Host "Local restored copy: $restorePath"

Write-Host "Verifying Terraform can read restored state..."
terraform -chdir=$TerraformDir init -backend-config=dev.hcl
terraform -chdir=$TerraformDir state list | Select-Object -First 20

Write-Host "State restore complete."
