variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for naming and resource tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OpenID Connect Provider ARN."
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OpenID Connect Provider URL."
  type        = string
}
