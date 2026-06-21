variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint."
  type        = string
}

variable "eks_cluster_ca_cert" {
  description = "Base64 encoded EKS cluster certificate authority data."
  type        = string
  sensitive   = true
}

variable "eks_cluster_token" {
  description = "Bearer token used by Terraform providers to authenticate to EKS."
  type        = string
  sensitive   = true
}

variable "namespace" {
  description = "Namespace where ArgoCD is installed."
  type        = string
  default     = "argocd"
}

variable "helm_chart_version" {
  description = "ArgoCD Helm chart version."
  type        = string
  default     = "5.51.6"
}

variable "helm_repo_url" {
  description = "Official Argo Helm chart repository URL."
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "applications_repo_url" {
  description = "Git repository watched by ArgoCD for BlackTickets Helm manifests."
  type        = string
  default     = "https://github.com/BlackTickets-Platform/blacktickets-helm.git"
}

variable "applications_target_revision" {
  description = "Git revision watched by ArgoCD."
  type        = string
  default     = "main"
}

variable "applications_path" {
  description = "Path in the Helm repository for the microservice chart."
  type        = string
  default     = "charts/blacktickets"
}

variable "applications_values_file" {
  description = "Values file used by generated ArgoCD applications."
  type        = string
  default     = "values-dev.yaml"
}

variable "applications_destination_namespace" {
  description = "Destination namespace for generated applications."
  type        = string
  default     = "blacktickets-dev"
}
