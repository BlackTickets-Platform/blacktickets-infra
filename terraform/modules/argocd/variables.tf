variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID."
  type        = string
}

variable "db_host" {
  description = "RDS database hostname."
  type        = string
}

variable "poster_bucket_name" {
  description = "S3 bucket for posters."
  type        = string
}

variable "poster_cloudfront_domain" {
  description = "CloudFront domain for posters."
  type        = string
}

variable "booking_notification_queue_url" {
  description = "SQS queue URL for booking notifications."
  type        = string
}

variable "app_domain_name" {
  description = "Web application public domain."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the application load balancer."
  type        = string
  default     = null
}

variable "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint."
  type        = string
}

variable "eks_cluster_ca_cert" {
  description = "Base64 encoded EKS cluster certificate authority data."
  type        = string
  sensitive   = true
}

variable "eks_cluster_token" {
  description = "Bearer token used by Terraform providers to authenticate to EKS."
  type        = string
  sensitive   = true
}

variable "namespace" {
  description = "Namespace where ArgoCD is installed."
  type        = string
  default     = "argocd"
}

variable "helm_chart_version" {
  description = "ArgoCD Helm chart version."
  type        = string
  default     = "5.51.6"
}

variable "helm_repo_url" {
  description = "Official Argo Helm chart repository URL."
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "applications_repo_url" {
  description = "Git repository watched by ArgoCD for BlackTickets Helm manifests."
  type        = string
  default     = "https://github.com/BlackTickets-Platform/blacktickets-helm.git"
}

variable "applications_target_revision" {
  description = "Git revision watched by ArgoCD."
  type        = string
  default     = "main"
}

variable "applications_path" {
  description = "Path in the Helm repository for the microservice chart."
  type        = string
  default     = "charts/blacktickets"
}

variable "applications_values_file" {
  description = "Values file used by generated ArgoCD applications."
  type        = string
  default     = "values-dev.yaml"
}

variable "applications_destination_namespace" {
  description = "Destination namespace for generated applications."
  type        = string
  default     = "blacktickets-dev"
}

variable "bedrock_assume_role_arn" {
  description = "Optional IAM Role ARN in the old AWS account for Bedrock access."
  type        = string
  default     = null
}

variable "waf_web_acl_arn" {
  description = "ARN of the regional WAF Web ACL to associate with the Load Balancer."
  type        = string
  default     = ""
}

