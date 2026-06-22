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

output "alb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller service account."
  value       = module.irsa.alb_controller_role_arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for the External Secrets Operator service account."
  value       = module.irsa.external_secrets_role_arn
}

output "github_actions_deploy_role_arn" {
  description = "IAM role ARN GitHub Actions can assume through OIDC for Terraform deployments."
  value       = module.github_oidc.role_arn
}

output "role_arn" {
  description = "IAM role ARN GitHub Actions can assume through OIDC for Terraform deployments."
  value       = module.github_oidc.role_arn
}

output "github_actions_oidc_provider_arn" {
  description = "IAM OIDC provider ARN for GitHub Actions."
  value       = module.github_oidc.oidc_provider_arn
}

output "external_secrets_release_name" {
  description = "Terraform-managed External Secrets Operator Helm release name."
  value       = module.platform_addons.external_secrets_release_name
}

output "aws_load_balancer_controller_release_name" {
  description = "Terraform-managed AWS Load Balancer Controller Helm release name."
  value       = module.platform_addons.aws_load_balancer_controller_release_name
}

output "gateway_api_crds_manifest_url" {
  description = "Gateway API CRDs manifest URL applied by Terraform."
  value       = module.platform_addons.gateway_api_crds_manifest_url
}

output "aws_load_balancer_controller_gateway_crds_manifest_url" {
  description = "AWS Load Balancer Controller Gateway API CRDs manifest URL applied by Terraform."
  value       = module.platform_addons.aws_load_balancer_controller_gateway_crds_manifest_url
}

output "route53_zone_id" {
  description = "Route53 public hosted zone ID for the root domain."
  value       = module.edge.route53_zone_id
}

output "route53_name_servers" {
  description = "Route53 public hosted zone name servers to configure at the domain registrar."
  value       = module.edge.route53_name_servers
}

output "app_domain_name" {
  description = "Public DNS name for the BlackTickets web application."
  value       = module.edge.app_domain_name
}

output "app_dns_record_fqdn" {
  description = "Route53 DNS record FQDN for the BlackTickets web application."
  value       = module.edge.app_dns_record_fqdn
}

output "app_acm_certificate_arn" {
  description = "ACM certificate ARN for the BlackTickets web application."
  value       = module.edge.app_acm_certificate_arn
}
