variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "poster_bucket_id" {
  description = "ID/name of the poster S3 bucket."
  type        = string
}

variable "poster_bucket_arn" {
  description = "ARN of the poster S3 bucket."
  type        = string
}

variable "poster_bucket_domain" {
  description = "Regional domain name of the poster S3 bucket."
  type        = string
}

variable "domain_name" {
  description = "Optional public hosted zone domain name."
  type        = string
  default     = null
}

variable "create_route53_record" {
  description = "Whether to create a Route53 alias record for poster CloudFront."
  type        = bool
  default     = false
}
