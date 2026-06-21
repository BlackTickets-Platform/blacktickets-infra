output "namespace" {
  description = "Namespace where ArgoCD is installed."
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "helm_release_name" {
  description = "ArgoCD Helm release name."
  value       = helm_release.argocd.name
}

output "application_name" {
  description = "BlackTickets ArgoCD Application name."
  value       = "blacktickets"
}
