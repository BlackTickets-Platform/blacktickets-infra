locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"
  github_subject  = "repo:${var.github_org}/${var.github_repo}:*"

  common_tags = {
    Project     = "blacktickets"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url = local.github_oidc_url

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b2ffe8383d1b1e1b3f"
  ]

  tags = merge(local.common_tags, {
    Name = "github-actions-oidc"
  })
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        local.github_subject
      ]
    }
  }
}

data "aws_iam_policy_document" "administrator_access" {
  statement {
    actions = [
      "*"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = merge(local.common_tags, {
    Name = var.role_name
  })
}

resource "aws_iam_role_policy" "administrator_access" {
  name   = "${var.role_name}-administrator-access"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.administrator_access.json
}
