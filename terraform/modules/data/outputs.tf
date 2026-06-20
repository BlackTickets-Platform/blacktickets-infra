output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint address."
  value       = aws_db_instance.postgres.address
}

output "rds_instance_identifier" {
  description = "Identifier of the RDS PostgreSQL instance."
  value       = aws_db_instance.postgres.identifier
}

output "poster_bucket_name" {
  description = "Name of the S3 bucket used for event poster uploads."
  value       = aws_s3_bucket.posters.bucket
}

output "poster_bucket_arn" {
  description = "ARN of the S3 bucket used for event poster uploads."
  value       = aws_s3_bucket.posters.arn
}

output "poster_bucket_regional_domain_name" {
  description = "Regional domain name of the poster bucket."
  value       = aws_s3_bucket.posters.bucket_regional_domain_name
}

output "booking_notifications_queue_url" {
  description = "URL of the booking notifications SQS queue."
  value       = aws_sqs_queue.booking_notifications.url
}

output "booking_notifications_queue_arn" {
  description = "ARN of the booking notifications SQS queue."
  value       = aws_sqs_queue.booking_notifications.arn
}

output "booking_notifications_queue_name" {
  description = "Name of the booking notifications SQS queue."
  value       = aws_sqs_queue.booking_notifications.name
}

output "booking_notifications_sns_topic_arn" {
  description = "ARN of the SNS topic used for booking notification emails."
  value       = aws_sns_topic.booking_notifications.arn
}

output "booking_notification_lambda_name" {
  description = "Name of the booking notification Lambda consumer."
  value       = aws_lambda_function.booking_notification_consumer.function_name
}

output "booking_notification_lambda_arn" {
  description = "ARN of the booking notification Lambda consumer."
  value       = aws_lambda_function.booking_notification_consumer.arn
}
