output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server."
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded EKS cluster CA data."
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA."
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "Issuer URL of the EKS OIDC provider."
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "node_role_arn" {
  description = "IAM role ARN used by the default managed node group."
  value       = aws_iam_role.node.arn
}
