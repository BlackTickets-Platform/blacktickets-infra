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
