output "vpc_id" {
  description = "ID of the BlackTickets VPC."
  value       = module.networking.vpc_id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "ecr_repository_urls" {
  description = "ECR repository URLs keyed by service name."
  value       = module.ecr.repository_urls
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint address."
  value       = module.data.rds_endpoint
}

output "poster_bucket_name" {
  description = "Name of the poster image bucket."
  value       = module.data.poster_bucket_name
}

output "poster_cloudfront_domain_name" {
  description = "CloudFront domain name for poster images."
  value       = module.edge.poster_cloudfront_domain_name
}

output "irsa_role_arns" {
  description = "IRSA role ARNs keyed by service account."
  value       = module.irsa.role_arns
}
