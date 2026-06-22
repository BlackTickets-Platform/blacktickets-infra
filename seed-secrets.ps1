param(
  [string]$Region = "us-east-1",
  [string]$SecretName = "blacktickets-dev/app-config",
  [string]$DbName = "blacktickets",
  [string]$DbUser = "postgres",
  [string]$DbPort = "5432",
  [string]$AdminEmail = "admin@blacktickets.com",
  [string]$UserEmail = "user@blacktickets.com"
)

$ErrorActionPreference = "Stop"

$InfraRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TerraformDir = Join-Path $InfraRoot "terraform"

function Get-PlainSecret {
  param(
    [Parameter(Mandatory = $true)]
    [string]$EnvName,
    [Parameter(Mandatory = $true)]
    [string]$Prompt
  )

  $value = [Environment]::GetEnvironmentVariable($EnvName)
  if (-not [string]::IsNullOrWhiteSpace($value)) {
    return $value
  }

  if ($EnvName -eq "TF_VAR_db_password" -and -not [string]::IsNullOrWhiteSpace($env:TF_VAR_db_password)) {
    return $env:TF_VAR_db_password
  }

  $secure = Read-Host $Prompt -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

function Get-TerraformOutput {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  Push-Location $TerraformDir
  try {
    $value = terraform output -raw $Name 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($value)) {
      return $value.Trim()
    }
  }
  finally {
    Pop-Location
  }

  return $null
}

Write-Host "Preparing app config secret payload without printing secret values..."

$dbHost = Get-TerraformOutput -Name "rds_endpoint"
if ([string]::IsNullOrWhiteSpace($dbHost)) {
  $dbHost = Read-Host "RDS endpoint hostname"
}

$queueUrl = Get-TerraformOutput -Name "booking_notifications_queue_url"
if ([string]::IsNullOrWhiteSpace($queueUrl)) {
  $queueUrl = aws sqs get-queue-url `
    --queue-name "blacktickets-dev-booking-notifications" `
    --region $Region `
    --query "QueueUrl" `
    --output text 2>$null
}

if ([string]::IsNullOrWhiteSpace($queueUrl) -or $queueUrl -eq "None") {
  $queueUrl = ""
}

$dbPassword = Get-PlainSecret -EnvName "TF_VAR_db_password" -Prompt "DB password"
$jwtSecret = Get-PlainSecret -EnvName "BLACKTICKETS_JWT_SECRET" -Prompt "JWT secret"
$internalToken = Get-PlainSecret -EnvName "BLACKTICKETS_INTERNAL_SERVICE_TOKEN" -Prompt "Internal service token"
$adminPassword = Get-PlainSecret -EnvName "BLACKTICKETS_ADMIN_PASSWORD" -Prompt "Admin password"
$userPassword = Get-PlainSecret -EnvName "BLACKTICKETS_USER_PASSWORD" -Prompt "User password"

$payload = [ordered]@{
  BOOKING_NOTIFICATION_QUEUE_URL = $queueUrl
  DB_PORT                        = $DbPort
  DB_HOST                        = $dbHost
  USER_PASSWORD                  = $userPassword
  DB_PASSWORD                    = $dbPassword
  JWT_SECRET                     = $jwtSecret
  ADMIN_PASSWORD                 = $adminPassword
  USER_EMAIL                     = $UserEmail
  INTERNAL_SERVICE_TOKEN         = $internalToken
  DB_PASS                        = $dbPassword
  DB_USER                        = $DbUser
  ADMIN_EMAIL                    = $AdminEmail
  DB_NAME                        = $DbName
}

$json = $payload | ConvertTo-Json -Compress

Write-Host "Checking Secrets Manager secret: $SecretName"
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
aws secretsmanager describe-secret --secret-id $SecretName --region $Region *> $null
$describeExit = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference

if ($describeExit -eq 0) {
  Write-Host "Updating existing secret value."
  aws secretsmanager put-secret-value `
    --secret-id $SecretName `
    --secret-string $json `
    --region $Region | Out-Null
} else {
  Write-Host "Secret was missing. Creating it now."
  aws secretsmanager create-secret `
    --name $SecretName `
    --description "Runtime application configuration for BlackTickets." `
    --secret-string $json `
    --region $Region | Out-Null
}

if ($LASTEXITCODE -ne 0) {
  throw "Failed to seed Secrets Manager secret $SecretName."
}

Write-Host "Secrets Manager app config seeded successfully."
