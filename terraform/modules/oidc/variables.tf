variable "github_org" {
  description = "GitHub organization that owns the Terraform repository."
  type        = string
  default     = "BlackTickets-Platform"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the deployment role."
  type        = string
  default     = "blacktickets-infra"
}

variable "role_name" {
  description = "IAM role name for GitHub Actions Terraform deployment."
  type        = string
  default     = "blacktickets-dev-github-terraform-deploy"
}

variable "services_github_repo" {
  description = "GitHub repository allowed to assume the service image push role."
  type        = string
  default     = "blacktickets-services"
}

variable "ecr_push_role_name" {
  description = "IAM role name for GitHub Actions service image pushes to ECR."
  type        = string
  default     = "blacktickets-dev-github-ecr-push"
}
