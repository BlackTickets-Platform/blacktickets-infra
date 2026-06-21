# ArgoCD Module

This module installs ArgoCD into the EKS cluster and creates an ArgoCD Application for the BlackTickets Helm chart.

ArgoCD continuously compares the desired state in Git with the live Kubernetes cluster. When the Helm repository changes, ArgoCD can sync those changes into the cluster without manually running `helm upgrade`.

## Trust And Access

Terraform connects to EKS using the cluster endpoint, certificate authority, and short-lived token passed from the root module. ArgoCD is installed with the official `argo-cd` Helm chart into the `argocd` namespace.

The ArgoCD server service is configured as `ClusterIP`, so it is internal to the cluster.

## Access The UI

After Terraform applies this module, port-forward the ArgoCD server:

```powershell
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Then open:

```text
http://localhost:8080
```

## Initial Admin Password

Get the initial password with:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | %{ [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }
```

Username:

```text
admin
```

## GitOps Workflow

The Application watches:

```text
https://github.com/BlackTickets-Platform/blacktickets-helm.git
```

Target revision:

```text
main
```

Chart path:

```text
charts/blacktickets
```

Values file:

```text
values-dev.yaml
```

Auto-sync, self-heal, and namespace creation are enabled.
