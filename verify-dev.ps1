param(
  [string]$Region = "us-east-1",
  [string]$ClusterName = "blacktickets-dev",
  [string]$Namespace = "blacktickets-dev",
  [string]$ApplicationName = "blacktickets",
  [string]$Url = "https://blacktickets.ananthapps.site"
)

$ErrorActionPreference = "Stop"

Write-Host "Updating kubeconfig..."
aws eks update-kubeconfig --region $Region --name $ClusterName | Out-Host

Write-Host "Checking ArgoCD application..."
kubectl get application $ApplicationName -n argocd

Write-Host "Checking pods..."
kubectl get pods -n $Namespace

Write-Host "Checking ExternalSecret..."
kubectl get externalsecret -n $Namespace

Write-Host "Checking Gateway..."
kubectl get gateway $ApplicationName -n $Namespace -o wide

Write-Host "Checking HTTPS endpoint..."
try {
  $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 30
  Write-Host "HTTPS status: $($response.StatusCode)"
}
catch {
  throw "HTTPS check failed for ${Url}: $($_.Exception.Message)"
}

Write-Host "Development stack verification complete."
