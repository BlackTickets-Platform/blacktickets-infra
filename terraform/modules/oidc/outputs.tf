output "role_arn" {
  description = "ARN of the IAM role GitHub Actions can assume through OIDC."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions IAM OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}
