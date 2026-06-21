output "external_secrets_namespace" {
  description = "Namespace where External Secrets Operator is installed."
  value       = kubernetes_namespace.external_secrets.metadata[0].name
}

output "external_secrets_release_name" {
  description = "External Secrets Operator Helm release name."
  value       = helm_release.external_secrets.name
}

output "aws_load_balancer_controller_release_name" {
  description = "AWS Load Balancer Controller Helm release name."
  value       = helm_release.aws_load_balancer_controller.name
}

output "gateway_api_crds_manifest_url" {
  description = "Gateway API CRDs manifest URL applied by Terraform."
  value       = null_resource.gateway_api_crds.triggers.manifest_url
}
