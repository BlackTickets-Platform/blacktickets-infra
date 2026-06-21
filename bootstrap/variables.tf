variable "region" {
  description = "AWS region for the Terraform backend bootstrap resources."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform remote state."
  type        = string
  default     = "blacktickets-dev-tfstate"
}

variable "dynamodb_table" {
  description = "DynamoDB table name for Terraform state locking."
  type        = string
  default     = "blacktickets-dev-terraform-locks"
}
