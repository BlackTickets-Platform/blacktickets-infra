terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  is_windows  = dirname("/") == "\\"

  prometheus_app_cmd_windows = <<-EOT
    $ErrorActionPreference = "Stop"
    aws eks update-kubeconfig --region "${var.aws_region}" --name "${var.cluster_name}"
    
    $manifest = @(
      "apiVersion: argoproj.io/v1alpha1",
      "kind: Application",
      "metadata:",
      "  name: prometheus-stack",
      "  namespace: argocd",
      "spec:",
      "  project: default",
      "  source:",
      "    repoURL: `"https://prometheus-community.github.io/helm-charts`"",
      "    targetRevision: `"61.3.0`"",
      "    chart: kube-prometheus-stack",
      "    helm:",
      "      values: |",
      "        prometheus:",
      "          prometheusSpec:",
      "            serviceMonitorSelectorNilUsesHelmValues: false",
      "            serviceMonitorSelector: {}",
      "            storageSpec:",
      "              volumeClaimTemplate:",
      "                spec:",
      "                  storageClassName: ebs-sc",
      "                  accessModes: [`"ReadWriteOnce`"]",
      "                  resources:",
      "                    requests:",
      "                      storage: 10Gi",
      "        grafana:",
      "          sidecar:",
      "            dashboards:",
      "              enabled: true",
      "              label: grafana_dashboard",
      "              labelValue: `"1`"",
      "          persistence:",
      "            enabled: true",
      "            storageClassName: ebs-sc",
      "            accessModes: [`"ReadWriteOnce`"]",
      "            size: 10Gi",
      "          adminPassword: `"admin`"",
      "  destination:",
      "    server: https://kubernetes.default.svc",
      "    namespace: monitoring",
      "  syncPolicy:",
      "    automated:",
      "      prune: true",
      "      selfHeal: true",
      "    syncOptions:",
      "      - CreateNamespace=true",
      "      - SkipDryRunOnMissingResource=true",
      "      - ServerSideApply=true"
    ) -join "`n"

    $manifest | kubectl apply -n argocd -f -
    Write-Host "Prometheus ArgoCD Application applied successfully."
  EOT

  prometheus_app_cmd_unix = <<-EOT
    set -e
    aws eks update-kubeconfig --region "${var.aws_region}" --name "${var.cluster_name}"
    
    cat <<EOF | kubectl apply -n argocd -f -
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: prometheus-stack
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: "https://prometheus-community.github.io/helm-charts"
        targetRevision: "61.3.0"
        chart: kube-prometheus-stack
        helm:
          values: |
            prometheus:
              prometheusSpec:
                serviceMonitorSelectorNilUsesHelmValues: false
                serviceMonitorSelector: {}
                storageSpec:
                  volumeClaimTemplate:
                    spec:
                      storageClassName: ebs-sc
                      accessModes: ["ReadWriteOnce"]
                      resources:
                        requests:
                          storage: 10Gi
            grafana:
              sidecar:
                dashboards:
                  enabled: true
                  label: grafana_dashboard
                  labelValue: "1"
              persistence:
                enabled: true
                storageClassName: ebs-sc
                accessModes: ["ReadWriteOnce"]
                size: 10Gi
              adminPassword: "admin"
      destination:
        server: https://kubernetes.default.svc
        namespace: monitoring
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - SkipDryRunOnMissingResource=true
          - ServerSideApply=true
    EOF
    echo "Prometheus ArgoCD Application applied successfully."
  EOT

  prometheus_app_cmd = local.is_windows ? local.prometheus_app_cmd_windows : local.prometheus_app_cmd_unix
}

# 1. Create Monitoring Namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# 2. AWS EBS CSI Driver IAM Role & Policy Attachments
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${local.name_prefix}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = {
    Name        = "${local.name_prefix}-ebs-csi-driver-role"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# 3. Deploy EKS EBS CSI Addon
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# 4. StorageClass for EBS CSI GP3 Volumes
resource "kubernetes_storage_class" "ebs_sc" {
  metadata {
    name = "ebs-sc"
  }

  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type = "gp3"
  }

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}

# 5. ArgoCD application deployment for Prometheus Stack
resource "null_resource" "prometheus_stack" {
  triggers = {
    cluster_name   = var.cluster_name
    prometheus_cmd = sha256(local.prometheus_app_cmd)
  }

  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell", "-NoProfile", "-Command"] : ["/bin/sh", "-c"]
    command     = local.prometheus_app_cmd
  }

  depends_on = [
    kubernetes_namespace.monitoring,
    kubernetes_storage_class.ebs_sc
  ]
}

# 6. ConfigMaps for Grafana Custom Dashboards
resource "kubernetes_config_map" "application_dashboard" {
  metadata {
    name      = "blacktickets-application-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "application-dashboard.json" = file("${path.module}/files/application-dashboard.json")
  }
}

resource "kubernetes_config_map" "business_dashboard" {
  metadata {
    name      = "blacktickets-business-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "business-dashboard.json" = file("${path.module}/files/business-dashboard.json")
  }
}

resource "kubernetes_config_map" "infrastructure_dashboard" {
  metadata {
    name      = "blacktickets-infrastructure-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "infrastructure-dashboard.json" = file("${path.module}/files/infrastructure-dashboard.json")
  }
}
