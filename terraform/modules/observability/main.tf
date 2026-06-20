locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  alarm_actions         = [var.sns_topic_arn]
  cloudtrail_name       = "${local.name_prefix}-trail"
  cloudtrail_bucket     = "${local.name_prefix}-cloudtrail-logs"
  cloudtrail_log_group  = "/aws/cloudtrail/${local.name_prefix}"
  cloudtrail_source_arn = "arn:aws:cloudtrail:${var.aws_region}:${var.account_id}:trail/${local.cloudtrail_name}"
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  alarm_description   = "RDS PostgreSQL CPU utilization is at least 80% for 5 minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 80
  period              = 300
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-cpu-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${local.name_prefix}-rds-free-storage-low"
  alarm_description   = "RDS PostgreSQL free storage is 5 GB or lower."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 5368709120
  period              = 300
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-free-storage-low"
  })
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.name_prefix}-lambda-errors"
  alarm_description   = "Booking notification Lambda has at least 1 error in 5 minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  period              = 300
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-errors"
  })
}

resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth_high" {
  alarm_name          = "${local.name_prefix}-sqs-queue-depth-high"
  alarm_description   = "Booking notifications SQS queue has at least 10 visible messages."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 10
  period              = 300
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions

  dimensions = {
    QueueName = var.sqs_queue_name
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sqs-queue-depth-high"
  })
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "/aws/eks/${var.eks_cluster_name}/cluster"
  })
}

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "BlackTickets-${var.environment}-Operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "EKS Cluster"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", "ClusterName", var.eks_cluster_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "RDS PostgreSQL"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_identifier],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeStorageSpace", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "Lambda"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "SQS"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_queue_name],
            [".", "NumberOfMessagesSent", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Poster CloudFront"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", var.poster_cloudfront_distribution_id, "Region", "Global"],
            [".", "BytesDownloaded", ".", ".", ".", "."]
          ]
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = local.cloudtrail_bucket

  tags = merge(local.common_tags, {
    Name = local.cloudtrail_bucket
  })
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid = "AWSCloudTrailAclCheck"

    actions = ["s3:GetBucketAcl"]

    resources = [
      aws_s3_bucket.cloudtrail_logs.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [local.cloudtrail_source_arn]
    }
  }

  statement {
    sid = "AWSCloudTrailWrite"

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${var.account_id}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [local.cloudtrail_source_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = local.cloudtrail_log_group
  retention_in_days = 90

  tags = merge(local.common_tags, {
    Name = local.cloudtrail_log_group
  })
}

data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch_logs" {
  name               = "${local.name_prefix}-cloudtrail-cloudwatch-logs-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudtrail-cloudwatch-logs-role"
  })
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_logs" {
  statement {
    sid = "WriteCloudTrailLogs"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.cloudtrail.arn}:log-stream:${var.account_id}_CloudTrail_*"
    ]
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_logs" {
  name   = "${local.name_prefix}-cloudtrail-cloudwatch-logs-policy"
  role   = aws_iam_role.cloudtrail_cloudwatch_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs.json
}

resource "aws_cloudtrail" "main" {
  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_logs.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "${var.poster_bucket_arn}/"
      ]
    }
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs,
    aws_iam_role_policy.cloudtrail_cloudwatch_logs
  ]

  tags = merge(local.common_tags, {
    Name = local.cloudtrail_name
  })
}
