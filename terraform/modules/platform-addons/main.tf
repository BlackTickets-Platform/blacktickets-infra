terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "null_resource" "gateway_api_crds" {
  triggers = {
    manifest_url = var.gateway_api_crds_url
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = "Stop"
      kubectl apply -f "${var.gateway_api_crds_url}"
    EOT
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.external_secrets_chart_version

  values = [
    yamlencode({
      installCRDs = true

      serviceAccount = {
        create = true
        name   = "external-secrets"
        annotations = {
          "eks.amazonaws.com/role-arn" = var.external_secrets_role_arn
        }
      }
    })
  ]
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.aws_load_balancer_controller_chart_version

  values = [
    yamlencode({
      clusterName = var.cluster_name
      region      = var.aws_region
      vpcId       = var.vpc_id

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = var.alb_controller_role_arn
        }
      }
    })
  ]

  depends_on = [
    null_resource.gateway_api_crds
  ]
}
