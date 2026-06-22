variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by the AWS Load Balancer Controller."
  type        = string
}

variable "external_secrets_role_arn" {
  description = "IRSA role ARN for the External Secrets Operator service account."
  type        = string
}

variable "alb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller service account."
  type        = string
}

variable "external_secrets_chart_version" {
  description = "External Secrets Operator Helm chart version."
  type        = string
  default     = "0.10.5"
}

variable "aws_load_balancer_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version."
  type        = string
  default     = "1.14.0"
}

variable "gateway_api_crds_url" {
  description = "Gateway API standard CRDs manifest URL."
  type        = string
  default     = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml"
}

variable "aws_load_balancer_controller_gateway_crds_url" {
  description = "AWS Load Balancer Controller Gateway API CRDs manifest URL."
  type        = string
  default     = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/config/crd/gateway/gateway-crds.yaml"
}
