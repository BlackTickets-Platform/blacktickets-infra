variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region that contains the application secrets."
  type        = string
}

variable "account_id" {
  description = "AWS account ID that contains the application secrets."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS IAM OIDC provider."
  type        = string
}

variable "oidc_provider_url" {
  description = "Issuer URL of the EKS IAM OIDC provider."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace that owns the service accounts."
  type        = string
}

variable "poster_bucket_arn" {
  description = "ARN of the S3 poster bucket."
  type        = string
}

variable "booking_notifications_queue_arn" {
  description = "ARN of the booking notifications SQS queue."
  type        = string
}

variable "bedrock_model_arn" {
  description = "ARN of the Bedrock model the chatbot can invoke."
  type        = string
}

variable "bedrock_assume_role_arn" {
  description = "Optional IAM Role ARN in the old AWS account for Bedrock access."
  type        = string
  default     = null
}
