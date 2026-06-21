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

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private EKS/application subnets."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "eks_cluster_version" {
  description = "EKS Kubernetes control plane version."
  type        = string
  default     = "1.31"
}

variable "eks_api_ingress_cidrs" {
  description = "CIDR blocks allowed to access the EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for the managed EKS node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 4
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "identity_db"
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL master password."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) > 0
    error_message = "db_password must be provided from a secret source such as GitHub Secrets DB_PASSWORD."
  }
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated RDS storage in GB."
  type        = number
  default     = 20
}

variable "rds_port" {
  description = "Database port for RDS PostgreSQL."
  type        = number
  default     = 5432
}

variable "poster_bucket_name" {
  description = "S3 bucket name used for uploaded event poster images."
  type        = string
}

variable "notification_email" {
  description = "Email address subscribed to booking notification messages through SNS."
  type        = string
}

variable "domain_name" {
  description = "Optional Route53 hosted zone domain name for edge records."
  type        = string
  default     = null
}

variable "create_route53_record" {
  description = "Whether to create Route53 records for the CloudFront distribution."
  type        = bool
  default     = false
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "blacktickets-dev"
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS node group (private-app subnets)."
  type        = list(string)
  default     = ["subnet-0ad6c3c579c0cef95", "subnet-051c4066c8371e280"]
}

variable "db_host" {
  description = "RDS endpoint hostname."
  type        = string
  default     = "blacktickets-dev-postgres.cqpkso2i290v.us-east-1.rds.amazonaws.com"
}
