variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC for security groups."
  type        = string
}

variable "eks_api_ingress_cidrs" {
  description = "CIDR blocks allowed to access the EKS API endpoint."
  type        = list(string)
}

variable "rds_port" {
  description = "Database port allowed from EKS workloads to RDS."
  type        = number
}
