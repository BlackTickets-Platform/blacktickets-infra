variable "aws_region" {
  description = "AWS region for BlackTickets infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for naming and tagging."
  type        = string
  default     = "blacktickets"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}
