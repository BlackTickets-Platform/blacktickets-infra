# clean-leftovers.ps1
# Wipes all remaining development resources for blacktickets in us-east-1

$Region = "us-east-1"
$ErrorActionPreference = "Continue"

Write-Host "Starting AWS leftovers cleanup..."

# 1. Secrets Manager
Write-Host "`nDeleting Secrets Manager secret..."
aws secretsmanager delete-secret --secret-id "blacktickets-dev/app-config" --force-delete-without-recovery --region $Region

# 2. CloudWatch Log Groups
Write-Host "`nDeleting CloudWatch Log Groups..."
$logGroups = @(
  "/aws/eks/blacktickets-dev/cluster",
  "/aws/lambda/blacktickets-dev-booking-notification-consumer",
  "/aws/cloudtrail/blacktickets-dev"
)
foreach ($lg in $logGroups) {
  aws logs delete-log-group --log-group-name $lg --region $Region
}

# 3. DynamoDB Tables
Write-Host "`nDeleting DynamoDB Tables..."
$tables = @(
  "blacktickets-dev-terraform-locks",
  "terrform-state-lock"
)
foreach ($table in $tables) {
  aws dynamodb delete-table --table-name $table --region $Region
}

# 4. ECR Repositories
Write-Host "`nDeleting ECR Repositories..."
$ecrs = @(
  "blacktickets-frontend",
  "blacktickets-identity-service",
  "blacktickets-booking-service",
  "blacktickets-event-service",
  "blacktickets-chatbot-service"
)
foreach ($ecr in $ecrs) {
  aws ecr delete-repository --repository-name $ecr --force --region $Region
}

# 5. CloudWatch Alarms
Write-Host "`nDeleting CloudWatch Alarms..."
$alarms = @(
  "blacktickets-dev-ec2-cpu-high",
  "blacktickets-dev-lambda-errors",
  "blacktickets-dev-private-alb-target-5xx-errors",
  "blacktickets-dev-public-alb-5xx-errors",
  "blacktickets-dev-rds-cpu-high",
  "blacktickets-dev-rds-free-storage-low",
  "blacktickets-dev-sqs-queue-depth-high"
)
foreach ($alarm in $alarms) {
  aws cloudwatch delete-alarms --alarm-names $alarm --region $Region
}

# 6. RDS Subnet Groups
Write-Host "`nDeleting RDS Subnet Groups..."
$subnetGroups = @(
  "blacktickets-dev-db-subnet-group",
  "blacktickets-dev-eks-db-subnet-group"
)
foreach ($sng in $subnetGroups) {
  aws rds delete-db-subnet-group --db-subnet-group-name $sng --region $Region
}

# 7. ACM Certificate
Write-Host "`nDeleting ACM Certificate..."
$certsJson = aws acm list-certificates --region $Region 2>$null
if ($LASTEXITCODE -eq 0 -and $certsJson) {
  $certs = ($certsJson | ConvertFrom-Json).CertificateSummaryList
  $targetCert = $certs | Where-Object { $_.DomainName -eq "blacktickets.ananthapps.site" }
  if ($targetCert) {
    aws acm delete-certificate --certificate-arn $targetCert.CertificateArn --region $Region
  }
}

# 8. WAFv2 Web ACL
Write-Host "`nDeleting WAFv2 Web ACL..."
$webAclsJson = aws wafv2 list-web-acls --scope REGIONAL --region $Region 2>$null
if ($LASTEXITCODE -eq 0 -and $webAclsJson) {
  $webAcls = ($webAclsJson | ConvertFrom-Json).WebACLs
  $targetAcl = $webAcls | Where-Object { $_.Name -eq "blacktickets-dev-web-acl" }
  if ($targetAcl) {
    $detailsJson = aws wafv2 get-web-acl --name "blacktickets-dev-web-acl" --id $targetAcl.Id --scope REGIONAL --region $Region 2>$null
    if ($LASTEXITCODE -eq 0 -and $detailsJson) {
      $lockToken = ($detailsJson | ConvertFrom-Json).LockToken
      aws wafv2 delete-web-acl --name "blacktickets-dev-web-acl" --id $targetAcl.Id --scope REGIONAL --lock-token $lockToken --region $Region
    }
  }
}

# 9. IAM EKS OIDC Providers (Keep GitHub OIDC provider untouched)
Write-Host "`nDeleting IAM EKS OIDC Providers..."
$oidcJson = aws iam list-open-id-connect-providers 2>$null
if ($LASTEXITCODE -eq 0 -and $oidcJson) {
  $oidcProviders = ($oidcJson | ConvertFrom-Json).OpenIDConnectProviderList
  foreach ($prov in $oidcProviders) {
    if ($prov.Arn -match "oidc.eks.us-east-1.amazonaws.com") {
      Write-Host "Deleting old EKS OIDC provider: $($prov.Arn)"
      aws iam delete-open-id-connect-provider --open-id-connect-provider-arn $prov.Arn
    }
  }
}

# 10. IAM Roles (including detaching and deleting policies)
Write-Host "`nDeleting IAM Roles..."
$roles = @(
  "blacktickets-dev-aws-load-balancer-controller-irsa",
  "blacktickets-dev-booking-notification-consumer-role",
  "blacktickets-dev-booking-notification-lambda-role",
  "blacktickets-dev-booking-service-irsa",
  "blacktickets-dev-chatbot-service-irsa",
  "blacktickets-dev-cloudtrail-cloudwatch-logs-role",
  "blacktickets-dev-ec2-app-role",
  "blacktickets-dev-eks-cluster-role",
  "blacktickets-dev-eks-node-role",
  "blacktickets-dev-event-service-irsa",
  "blacktickets-dev-external-secrets-irsa",
  "blacktickets-dev-github-ecr-push",
  "blacktickets-dev-github-terraform-deploy"
)

foreach ($role in $roles) {
  Write-Host "Processing IAM Role: $role"

  # Detach attached policies
  $attachedPoliciesJson = aws iam list-attached-role-policies --role-name $role 2>$null
  if ($LASTEXITCODE -eq 0 -and $attachedPoliciesJson) {
    $attachedPolicies = ($attachedPoliciesJson | ConvertFrom-Json).AttachedPolicies
    foreach ($policy in $attachedPolicies) {
      Write-Host "Detaching policy $($policy.PolicyArn) from $role"
      aws iam detach-role-policy --role-name $role --policy-arn $policy.PolicyArn
    }
  }

  # Delete inline policies
  $inlinePoliciesJson = aws iam list-role-policies --role-name $role 2>$null
  if ($LASTEXITCODE -eq 0 -and $inlinePoliciesJson) {
    $inlinePolicies = ($inlinePoliciesJson | ConvertFrom-Json).PolicyNames
    foreach ($policyName in $inlinePolicies) {
      Write-Host "Deleting inline policy $policyName from $role"
      aws iam delete-role-policy --role-name $role --policy-name $policyName
    }
  }

  # Remove role from instance profiles if EC2 role
  if ($role -eq "blacktickets-dev-ec2-app-role") {
    $instanceProfilesJson = aws iam list-instance-profiles-for-role --role-name $role 2>$null
    if ($LASTEXITCODE -eq 0 -and $instanceProfilesJson) {
      $profiles = ($instanceProfilesJson | ConvertFrom-Json).InstanceProfiles
      foreach ($profile in $profiles) {
        Write-Host "Removing $role from instance profile $($profile.InstanceProfileName)"
        aws iam remove-role-from-instance-profile --instance-profile-name $profile.InstanceProfileName --role-name $role
        Write-Host "Deleting instance profile $($profile.InstanceProfileName)"
        aws iam delete-instance-profile --instance-profile-name $profile.InstanceProfileName
      }
    }
  }

  # Delete the role
  aws iam delete-role --role-name $role
}

Write-Host "`nCleanup complete!"
