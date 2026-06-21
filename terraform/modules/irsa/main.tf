locals {
  name_prefix           = "${var.project_name}-${var.environment}"
  oidc_host             = replace(var.oidc_provider_url, "https://", "")
  app_config_secret_arn = "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:${local.name_prefix}/app-config-*"

  service_accounts = {
    event-service = {
      policy = data.aws_iam_policy_document.event_service.json
    }
    booking-service = {
      policy = data.aws_iam_policy_document.booking_service.json
    }
    chatbot-service = {
      policy = data.aws_iam_policy_document.chatbot_service.json
    }
  }

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "assume_role" {
  for_each = local.service_accounts

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${each.key}"]
    }
  }
}

data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
  }
}

data "aws_iam_policy_document" "event_service" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]

    resources = [
      "${var.poster_bucket_arn}/event-posters/*"
    ]
  }
}

data "aws_iam_policy_document" "booking_service" {
  statement {
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]

    resources = [
      var.booking_notifications_queue_arn
    ]
  }
}

data "aws_iam_policy_document" "chatbot_service" {
  statement {
    actions = [
      "bedrock:InvokeModel"
    ]

    resources = [
      var.bedrock_model_arn
    ]
  }
}

data "aws_iam_policy_document" "external_secrets" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      local.app_config_secret_arn
    ]
  }
}

resource "aws_iam_role" "service_account" {
  for_each = local.service_accounts

  name               = "${local.name_prefix}-${each.key}-irsa"
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-irsa"
  })

  lifecycle {
    ignore_changes = [assume_role_policy]
  }
}

resource "aws_iam_role_policy" "service_account" {
  for_each = local.service_accounts

  name   = "${local.name_prefix}-${each.key}-policy"
  role   = aws_iam_role.service_account[each.key].id
  policy = each.value.policy
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${local.name_prefix}-aws-load-balancer-controller-policy"
  description = "IAM policy for the AWS Load Balancer Controller."
  policy      = file("${path.module}/aws-load-balancer-controller-policy.json")

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aws-load-balancer-controller-policy"
  })
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "${local.name_prefix}-aws-load-balancer-controller-irsa"
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-aws-load-balancer-controller-irsa"
  })

  lifecycle {
    ignore_changes = [assume_role_policy]
  }
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "aws_iam_role" "external_secrets" {
  name               = "${local.name_prefix}-external-secrets-irsa"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-external-secrets-irsa"
  })

  lifecycle {
    ignore_changes = [assume_role_policy]
  }
}

resource "aws_iam_role_policy" "external_secrets" {
  name   = "${local.name_prefix}-external-secrets-policy"
  role   = aws_iam_role.external_secrets.id
  policy = data.aws_iam_policy_document.external_secrets.json
}
