variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "eks_cluster_name" {
  description = "EKS cluster name used for Kubernetes subnet discovery tags."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private EKS/application subnets."
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets."
  type        = list(string)
}
