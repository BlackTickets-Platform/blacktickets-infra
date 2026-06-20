variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes control plane version."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for EKS control plane and node group networking."
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster."
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired node count."
  type        = number
}

variable "node_min_size" {
  description = "Minimum node count."
  type        = number
}

variable "node_max_size" {
  description = "Maximum node count."
  type        = number
}
