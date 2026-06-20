variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region for regional observability resources."
  type        = string
}

variable "account_id" {
  description = "Current AWS account ID."
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "rds_instance_identifier" {
  description = "Identifier of the RDS PostgreSQL instance."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the booking notification Lambda consumer."
  type        = string
}

variable "sqs_queue_name" {
  description = "Name of the booking notifications SQS queue."
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic used for alarm actions."
  type        = string
}

variable "poster_cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution for private S3 poster images."
  type        = string
}

variable "poster_bucket_arn" {
  description = "ARN of the S3 bucket used for event poster uploads."
  type        = string
}
