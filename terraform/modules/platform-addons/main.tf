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

locals {
  is_windows = dirname("/") == "\\"

  gateway_api_crds_cmd_windows = <<-EOT
    $ErrorActionPreference = "Stop"
    kubectl apply -f "${var.gateway_api_crds_url}"
    kubectl apply -f "${var.aws_load_balancer_controller_gateway_crds_url}"
  EOT

  gateway_api_crds_cmd_unix = <<-EOT
    set -e
    kubectl apply -f "${var.gateway_api_crds_url}"
    kubectl apply -f "${var.aws_load_balancer_controller_gateway_crds_url}"
  EOT

  gateway_api_crds_cmd = local.is_windows ? local.gateway_api_crds_cmd_windows : local.gateway_api_crds_cmd_unix

  wait_for_lbc_webhook_cmd_windows = <<-EOT
    $ErrorActionPreference = "Stop"

    kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=180s

    for ($i = 1; $i -le 60; $i++) {
      $endpoint = kubectl get endpoints aws-load-balancer-webhook-service -n kube-system -o jsonpath="{.subsets[0].addresses[0].ip}" 2>$null
      if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($endpoint)) {
        Write-Host "AWS Load Balancer Controller webhook endpoint is ready: $endpoint"
        exit 0
      }

      Write-Host "Waiting for AWS Load Balancer Controller webhook endpoint... ($i/60)"
      Start-Sleep -Seconds 5
    }

    throw "Timed out waiting for aws-load-balancer-webhook-service endpoints."
  EOT

  wait_for_lbc_webhook_cmd_unix = <<-EOT
    set -e

    kubectl rollout status deployment/aws-load-balancer-controller -n kube-system --timeout=180s

    for i in $(seq 1 60); do
      endpoint=$(kubectl get endpoints aws-load-balancer-webhook-service -n kube-system -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null || true)
      if [ -n "$endpoint" ]; then
        echo "AWS Load Balancer Controller webhook endpoint is ready: $endpoint"
        exit 0
      fi

      echo "Waiting for AWS Load Balancer Controller webhook endpoint... ($i/60)"
      sleep 5
    done

    echo "Timed out waiting for aws-load-balancer-webhook-service endpoints."
    exit 1
  EOT

  wait_for_lbc_webhook_cmd = local.is_windows ? local.wait_for_lbc_webhook_cmd_windows : local.wait_for_lbc_webhook_cmd_unix
}

resource "null_resource" "gateway_api_crds" {
  triggers = {
    gateway_api_manifest_url = var.gateway_api_crds_url
    aws_lbc_manifest_url     = var.aws_load_balancer_controller_gateway_crds_url
  }

  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell", "-NoProfile", "-Command"] : ["/bin/sh", "-c"]
    command     = local.gateway_api_crds_cmd
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.external_secrets_chart_version
  wait       = false

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

  depends_on = [
    null_resource.wait_for_aws_load_balancer_webhook
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

      controllerConfig = {
        featureGates = {
          ALBGatewayAPI = true
        }
      }

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

resource "null_resource" "wait_for_aws_load_balancer_webhook" {
  depends_on = [
    helm_release.aws_load_balancer_controller
  ]

  triggers = {
    release = helm_release.aws_load_balancer_controller.metadata[0].revision
  }

  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell", "-NoProfile", "-Command"] : ["/bin/sh", "-c"]
    command     = local.wait_for_lbc_webhook_cmd
  }
}
