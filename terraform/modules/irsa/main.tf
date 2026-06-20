locals {
  name_prefix = "${var.project_name}-${var.environment}"
  oidc_host   = replace(var.oidc_provider_url, "https://", "")

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

resource "aws_iam_role" "service_account" {
  for_each = local.service_accounts

  name               = "${local.name_prefix}-${each.key}-irsa"
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-irsa"
  })
}

resource "aws_iam_role_policy" "service_account" {
  for_each = local.service_accounts

  name   = "${local.name_prefix}-${each.key}-policy"
  role   = aws_iam_role.service_account[each.key].id
  policy = each.value.policy
}
