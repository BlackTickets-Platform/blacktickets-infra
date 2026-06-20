variable "project_name" {
  description = "Project name used for resource tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "service_names" {
  description = "Service names that should have ECR repositories."
  type        = list(string)
}
