output "poster_cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution for poster images."
  value       = aws_cloudfront_distribution.posters.id
}

output "poster_cloudfront_domain_name" {
  description = "CloudFront domain name for poster images."
  value       = aws_cloudfront_distribution.posters.domain_name
}

output "waf_web_acl_arn" {
  description = "ARN of the regional WAF Web ACL."
  value       = aws_wafv2_web_acl.regional.arn
}

output "waf_web_acl_name" {
  description = "Name of the regional WAF Web ACL."
  value       = aws_wafv2_web_acl.regional.name
}
