locals {
  github_oidc_url         = "https://token.actions.githubusercontent.com"
  github_subject          = "repo:${var.github_org}/${var.github_repo}:*"
  services_github_subject = "repo:${var.github_org}/${var.services_github_repo}:*"

  common_tags = {
    Project     = "blacktickets"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "Anantha Kumar"
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

data "aws_iam_policy_document" "services_assume_role" {
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
        local.services_github_subject
      ]
    }
  }
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = [
      "arn:aws:ecr:*:*:repository/blacktickets-*"
    ]
  }
}

resource "aws_iam_role" "services_ecr_push" {
  name               = var.ecr_push_role_name
  assume_role_policy = data.aws_iam_policy_document.services_assume_role.json

  tags = merge(local.common_tags, {
    Name = var.ecr_push_role_name
  })
}

resource "aws_iam_role_policy" "services_ecr_push" {
  name   = "${var.ecr_push_role_name}-ecr-push"
  role   = aws_iam_role.services_ecr_push.id
  policy = data.aws_iam_policy_document.ecr_push.json
}
