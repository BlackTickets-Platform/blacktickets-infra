variable "project_name" {
  description = "Project name used for resource naming and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "private_db_subnet_ids" {
  description = "IDs of the private database subnets."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "ID of the RDS security group."
  type        = string
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
}

variable "db_password" {
  description = "PostgreSQL master password."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated RDS storage in GB."
  type        = number
}

variable "rds_port" {
  description = "Database port for RDS PostgreSQL."
  type        = number
}

variable "poster_bucket_name" {
  description = "S3 bucket name used for uploaded event poster images."
  type        = string
}

variable "notification_email" {
  description = "Email address subscribed to booking notification messages through SNS."
  type        = string
}
