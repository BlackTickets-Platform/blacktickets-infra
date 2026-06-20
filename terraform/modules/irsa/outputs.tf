output "role_arns" {
  description = "IRSA role ARNs keyed by Kubernetes service account name."
  value       = { for name, role in aws_iam_role.service_account : name => role.arn }
}
