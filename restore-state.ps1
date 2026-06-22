param(
  [string]$Region = "us-east-1",
  [string]$Bucket = "blacktickets-dev-tfstate",
  [string]$Key = "blacktickets/dev/terraform.tfstate",
  [string]$LockTable = "blacktickets-dev-terraform-locks",
  [string]$BackendConfig = "dev.hcl",
  [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

$InfraRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Join-Path $InfraRoot "terraform"
$BackupDir = Join-Path $InfraRoot "state-backups"

$DigestLockId = "$Bucket/$Key-md5"

function Set-StateDigest {
  param(
    [Parameter(Mandatory = $true)]
    [string]$StatePath
  )

  $digest = (Get-FileHash $StatePath -Algorithm MD5).Hash.ToLower()
  $itemPath = Join-Path $env:TEMP "terraform-state-digest-item.json"

  @{
    LockID = @{
      S = $DigestLockId
    }
    Digest = @{
      S = $digest
    }
  } | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $itemPath -NoNewline

  aws dynamodb put-item `
    --table-name $LockTable `
    --region $Region `
    --item "file://$itemPath" | Out-Null

  if ($LASTEXITCODE -ne 0) {
    throw "Failed to update Terraform state digest in DynamoDB."
  }

  Write-Host "Updated Terraform state digest in DynamoDB: $digest"
}

function Publish-StateFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$StatePath
  )

  aws s3api put-object `
    --bucket $Bucket `
    --key $Key `
    --region $Region `
    --body $StatePath `
    --content-type "application/json" | Out-Null

  if ($LASTEXITCODE -ne 0) {
    throw "Failed to upload Terraform state to s3://$Bucket/$Key."
  }

  Set-StateDigest -StatePath $StatePath
}

Set-Location $InfraRoot

if (-not (Test-Path $BackupDir)) {
  New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

Write-Host "Checking backend bucket..."
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
aws s3api head-bucket --bucket $Bucket *> $null
$headBucketExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
if ($headBucketExitCode -ne 0) {
  throw "Backend bucket '$Bucket' is missing or inaccessible. Run .\bootstrap.ps1 first."
}

Write-Host "Checking lock table..."
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
aws dynamodb describe-table --table-name $LockTable --region $Region *> $null
$describeTableExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
if ($describeTableExitCode -ne 0) {
  throw "DynamoDB lock table '$LockTable' is missing or inaccessible. Run .\bootstrap.ps1 first."
}

Write-Host "Checking remote Terraform state object..."
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
aws s3api head-object --bucket $Bucket --key $Key --region $Region *> $null
$headObjectExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
if ($headObjectExitCode -eq 0) {
  Write-Host "Remote state exists."

  $backupPath = Join-Path $BackupDir ("terraform-state-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".json")
  Write-Host "Pulling a local backup to $backupPath"
  Push-Location $TerraformDir
  try {
    terraform init -backend-config $BackendConfig
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed with exit code ${LASTEXITCODE}: terraform init -backend-config $BackendConfig"
    }

    terraform state pull > $backupPath
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed with exit code ${LASTEXITCODE}: terraform state pull"
    }
  }
  finally {
    Pop-Location
  }
  Write-Host "State backup complete."
  exit 0
}

Write-Host "Remote state object is missing. Looking for previous S3 object versions..."

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$versionsJson = aws s3api list-object-versions `
  --bucket $Bucket `
  --prefix $Key `
  --region $Region `
  --output json
$listVersionsExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

if ($listVersionsExitCode -ne 0) {
  throw "Unable to list S3 object versions for s3://$Bucket/$Key."
}

$objectVersions = ($versionsJson | ConvertFrom-Json).Versions
$versions = $objectVersions |
  Where-Object { $_.Key -eq $Key -and $_.IsLatest -ne $true } |
  Sort-Object LastModified -Descending

if (-not $versions -or $versions.Count -eq 0) {
  Write-Host "No previous S3 versions found. Looking for local Terraform state backups..."

  $localCandidates = @(
    Join-Path $TerraformDir "terraform.tfstate.backup"
    Join-Path $TerraformDir "terraform.tfstate"
  )

  $backupCandidates = Get-ChildItem -Path $BackupDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'terraform-state.*\.json$|restored-terraform-state.*\.json$' } |
    Sort-Object LastWriteTime -Descending |
    ForEach-Object { $_.FullName }

  $candidate = @($backupCandidates + $localCandidates) |
    Where-Object { Test-Path $_ } |
    Where-Object { (Get-Item $_).Length -gt 0 } |
    Select-Object -First 1

  if (-not $candidate) {
    throw "No previous S3 versions or local state backups found. State cannot be restored automatically; imports or rebuild are required."
  }

  Write-Host "Found local state backup:"
  Write-Host $candidate
  Write-Host "Size: $((Get-Item $candidate).Length)"
  Write-Host "MD5: $((Get-FileHash $candidate -Algorithm MD5).Hash.ToLower())"

  if (-not $AutoApprove) {
    $answer = Read-Host "Upload this local backup as the current remote Terraform state? Type yes to continue"
    if ($answer -ne "yes") {
      Write-Host "State restore skipped."
      exit 0
    }
  }

  Publish-StateFile -StatePath $candidate

  Write-Host "Uploaded local backup as remote Terraform state."
  Write-Host "Verifying Terraform can read restored state..."
  Push-Location $TerraformDir
  try {
    terraform init -backend-config $BackendConfig
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed with exit code ${LASTEXITCODE}: terraform init -backend-config $BackendConfig"
    }

    terraform state list | Select-Object -First 20
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed with exit code ${LASTEXITCODE}: terraform state list"
    }
  }
  finally {
    Pop-Location
  }

  Write-Host "State restore complete."
  exit 0
}

$version = $versions | Select-Object -First 1
Write-Host "Found previous state version:"
Write-Host "VersionId: $($version.VersionId)"
Write-Host "LastModified: $($version.LastModified)"
Write-Host "Size: $($version.Size)"

if (-not $AutoApprove) {
  $answer = Read-Host "Restore this version as the current Terraform state? Type yes to continue"
  if ($answer -ne "yes") {
    Write-Host "State restore skipped."
    exit 0
  }
}

$restorePath = Join-Path $BackupDir ("restored-terraform-state-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".json")

aws s3api get-object `
  --bucket $Bucket `
  --key $Key `
  --version-id $version.VersionId `
  --region $Region `
  $restorePath | Out-Null

Publish-StateFile -StatePath $restorePath

Write-Host "Restored state object from previous S3 version."
Write-Host "Local restored copy: $restorePath"

Write-Host "Verifying Terraform can read restored state..."
Push-Location $TerraformDir
try {
  terraform init -backend-config $BackendConfig
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform init -backend-config $BackendConfig"
  }

  terraform state list | Select-Object -First 20
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code ${LASTEXITCODE}: terraform state list"
  }
}
finally {
  Pop-Location
}

Write-Host "State restore complete."
