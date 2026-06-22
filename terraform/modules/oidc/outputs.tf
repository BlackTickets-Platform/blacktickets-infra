output "role_arn" {
  description = "ARN of the IAM role GitHub Actions can assume through OIDC."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions IAM OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "services_ecr_push_role_arn" {
  description = "ARN of the IAM role the services CI workflow can assume to push images to ECR."
  value       = aws_iam_role.services_ecr_push.arn
}
