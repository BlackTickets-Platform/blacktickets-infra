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

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = var.helm_repo_url
  chart      = "argo-cd"
  version    = var.helm_chart_version

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        extraArgs = [
          "--insecure"
        ]
      }

      applicationSet = {
        enabled = true
      }
    })
  ]
}

locals {
  is_windows = dirname("/") == "\\"

  argocd_app_cmd_windows = <<-EOT
    $ErrorActionPreference = "Stop"
    aws eks update-kubeconfig --region "${var.aws_region}" --name "${var.cluster_name}"
    Write-Host "Waiting for ArgoCD Application CRD..."
    for ($i = 1; $i -le 30; $i++) {
      kubectl get crd applications.argoproj.io *> $null
      if ($LASTEXITCODE -eq 0) {
        Write-Host "Application CRD found."
        break
      }
      if ($i -eq 30) {
        throw "Timed out waiting for applications.argoproj.io CRD"
      }
      Write-Host "Waiting... ($i/30)"
      Start-Sleep -Seconds 5
    }

    $manifest = @(
      "apiVersion: argoproj.io/v1alpha1",
      "kind: Application",
      "metadata:",
      "  name: blacktickets",
      "  namespace: ${kubernetes_namespace.argocd.metadata[0].name}",
      "spec:",
      "  project: default",
      "  source:",
      "    repoURL: `"${var.applications_repo_url}`"",
      "    targetRevision: ${var.applications_target_revision}",
      "    path: ${var.applications_path}",
      "    helm:",
      "      valueFiles:",
      "        - ${var.applications_values_file}",
      "      parameters:",
      "        - name: image.registry",
      "          value: `"${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com`"",
      "        - name: config.awsAccountId",
      "          value: `"${var.aws_account_id}`"",
      "        - name: config.awsRegion",
      "          value: `"${var.aws_region}`"",
      "        - name: config.dbHost",
      "          value: `"${var.db_host}`"",
      "        - name: config.posterBucketName",
      "          value: `"${var.poster_bucket_name}`"",
      "        - name: config.posterCdnDomain",
      "          value: `"${var.poster_cloudfront_domain}`"",
      "        - name: config.bookingNotificationQueueUrl",
      "          value: `"${var.booking_notification_queue_url}`"",
      "        - name: gateway.hostname",
      "          value: `"${var.app_domain_name}`"",
      "        - name: gateway.certificateArn",
      "          value: `"${var.acm_certificate_arn != null ? var.acm_certificate_arn : ""}`"",
      "        - name: gateway.wafv2Arn",
      "          value: `"${var.waf_web_acl_arn != null ? var.waf_web_acl_arn : ""}`"",
      "        - name: bedrock.roleArn",
      "          value: `"${var.bedrock_assume_role_arn != null ? var.bedrock_assume_role_arn : ""}`"",
      "  destination:",
      "    server: https://kubernetes.default.svc",
      "    namespace: ${var.applications_destination_namespace}",
      "  syncPolicy:",
      "    automated:",
      "      prune: true",
      "      selfHeal: true",
      "    syncOptions:",
      "      - CreateNamespace=true"
    ) -join "`n"

    $manifest | kubectl apply -n ${kubernetes_namespace.argocd.metadata[0].name} -f -

    Write-Host "Application applied successfully."
  EOT

  argocd_app_cmd_unix = <<-EOT
    set -e
    aws eks update-kubeconfig --region "${var.aws_region}" --name "${var.cluster_name}"
    echo "Waiting for ArgoCD Application CRD..."
    for i in $(seq 1 30); do
      if kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
        echo "Application CRD found."
        break
      fi
      if [ "$i" -eq 30 ]; then
        echo "Timed out waiting for applications.argoproj.io CRD"
        exit 1
      fi
      echo "Waiting... ($i/30)"
      sleep 5
    done

    cat <<EOF | kubectl apply -n ${kubernetes_namespace.argocd.metadata[0].name} -f -
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: blacktickets
      namespace: ${kubernetes_namespace.argocd.metadata[0].name}
    spec:
      project: default
      source:
        repoURL: "${var.applications_repo_url}"
        targetRevision: ${var.applications_target_revision}
        path: ${var.applications_path}
        helm:
          valueFiles:
            - ${var.applications_values_file}
          parameters:
            - name: image.registry
              value: "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
            - name: config.awsAccountId
              value: "${var.aws_account_id}"
            - name: config.awsRegion
              value: "${var.aws_region}"
            - name: config.dbHost
              value: "${var.db_host}"
            - name: config.posterBucketName
              value: "${var.poster_bucket_name}"
            - name: config.posterCdnDomain
              value: "${var.poster_cloudfront_domain}"
            - name: config.bookingNotificationQueueUrl
              value: "${var.booking_notification_queue_url}"
            - name: gateway.hostname
              value: "${var.app_domain_name}"
            - name: gateway.certificateArn
              value: "${var.acm_certificate_arn != null ? var.acm_certificate_arn : ""}"
            - name: gateway.wafv2Arn
              value: "${var.waf_web_acl_arn != null ? var.waf_web_acl_arn : ""}"
            - name: bedrock.roleArn
              value: "${var.bedrock_assume_role_arn != null ? var.bedrock_assume_role_arn : ""}"
      destination:
        server: https://kubernetes.default.svc
        namespace: ${var.applications_destination_namespace}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
    EOF

    echo "Application applied successfully."
  EOT

  argocd_app_cmd = local.is_windows ? local.argocd_app_cmd_windows : local.argocd_app_cmd_unix
}

resource "null_resource" "argocd_application" {
  depends_on = [
    helm_release.argocd
  ]

  triggers = {
    app_manifest_hash = sha256(jsonencode({
      repo                           = var.applications_repo_url
      target_revision                = var.applications_target_revision
      path                           = var.applications_path
      values                         = var.applications_values_file
      namespace                      = var.applications_destination_namespace
      argocd_namespace               = kubernetes_namespace.argocd.metadata[0].name
      aws_account_id                 = var.aws_account_id
      aws_region                     = var.aws_region
      db_host                        = var.db_host
      poster_bucket_name             = var.poster_bucket_name
      poster_cloudfront_domain       = var.poster_cloudfront_domain
      booking_notification_queue_url = var.booking_notification_queue_url
      app_domain_name                = var.app_domain_name
      acm_certificate_arn            = var.acm_certificate_arn
      bedrock_assume_role_arn        = var.bedrock_assume_role_arn
      waf_web_acl_arn                = var.waf_web_acl_arn
    }))
  }

  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell", "-NoProfile", "-Command"] : ["/bin/sh", "-c"]
    command     = local.argocd_app_cmd
  }
}

