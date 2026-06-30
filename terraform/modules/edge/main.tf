locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Anantha Kumar"
  }

  use_route53_zone = var.domain_name != null && (var.create_route53_zone || var.create_route53_record || var.app_domain_name != null)
  route53_zone_id  = var.domain_name == null ? null : var.create_route53_zone ? aws_route53_zone.public[0].zone_id : data.aws_route53_zone.selected[0].zone_id
}

resource "aws_cloudfront_origin_access_control" "posters" {
  name                              = "${local.name_prefix}-poster-oac"
  description                       = "OAC for private event poster bucket."
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "posters" {
  enabled             = true
  comment             = "${local.name_prefix} poster images"
  default_root_object = ""

  origin {
    domain_name              = var.poster_bucket_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.posters.id
    origin_id                = "poster-s3-origin"
  }

  default_cache_behavior {
    target_origin_id       = "poster-s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront.arn

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-poster-cdn"
  })
}

data "aws_iam_policy_document" "poster_bucket_cloudfront_read" {
  statement {
    actions = ["s3:GetObject"]

    resources = [
      "${var.poster_bucket_arn}/event-posters/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.posters.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "posters" {
  bucket = var.poster_bucket_id
  policy = data.aws_iam_policy_document.poster_bucket_cloudfront_read.json
}

resource "aws_wafv2_web_acl" "regional" {
  name        = "${local.name_prefix}-web-acl"
  description = "Regional WAF Web ACL for BlackTickets ingress resources."
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"

          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimit2000"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit2000"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-acl"
  })
}

resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "${local.name_prefix}-cloudfront-web-acl"
  description = "Global WAF Web ACL for BlackTickets CloudFront posters CDN."
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-cloudfront-web-acl"
    sampled_requests_enabled   = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudfront-web-acl"
  })
}

resource "aws_route53_zone" "public" {
  count = var.create_route53_zone && var.domain_name != null ? 1 : 0

  name = var.domain_name

  tags = merge(local.common_tags, {
    Name = var.domain_name
  })
}

data "aws_route53_zone" "selected" {
  count = local.use_route53_zone && !var.create_route53_zone ? 1 : 0

  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "app" {
  count = var.app_domain_name != null ? 1 : 0

  domain_name       = var.app_domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    "argocd.${var.domain_name}",
    "grafana.${var.domain_name}"
  ]

  tags = merge(local.common_tags, {
    Name = var.app_domain_name
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_certificate_validation" {
  for_each = var.app_domain_name == null ? {} : {
    for option in aws_acm_certificate.app[0].domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.route53_zone_id
}

resource "aws_route53_record" "app" {
  count = var.app_domain_name != null && var.app_load_balancer_dns_name != null ? 1 : 0

  zone_id = local.route53_zone_id
  name    = var.app_domain_name
  type    = "CNAME"
  ttl     = 60
  records = [var.app_load_balancer_dns_name]
}

resource "aws_route53_record" "argocd" {
  count = var.app_domain_name != null && var.app_load_balancer_dns_name != null ? 1 : 0

  zone_id = local.route53_zone_id
  name    = "argocd.${var.domain_name}"
  type    = "CNAME"
  ttl     = 60
  records = [var.app_load_balancer_dns_name]
}

resource "aws_route53_record" "grafana" {
  count = var.app_domain_name != null && var.app_load_balancer_dns_name != null ? 1 : 0

  zone_id = local.route53_zone_id
  name    = "grafana.${var.domain_name}"
  type    = "CNAME"
  ttl     = 60
  records = [var.app_load_balancer_dns_name]
}

resource "aws_route53_record" "posters" {
  count = var.create_route53_record && var.domain_name != null ? 1 : 0

  zone_id = local.route53_zone_id
  name    = "posters.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.posters.domain_name
    zone_id                = aws_cloudfront_distribution.posters.hosted_zone_id
    evaluate_target_health = false
  }
}
