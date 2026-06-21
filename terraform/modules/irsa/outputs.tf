output "role_arns" {
  description = "IRSA role ARNs keyed by Kubernetes service account name."
  value       = { for name, role in aws_iam_role.service_account : name => role.arn }
}

output "alb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller service account."
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for the External Secrets Operator service account."
  value       = aws_iam_role.external_secrets.arn
}
