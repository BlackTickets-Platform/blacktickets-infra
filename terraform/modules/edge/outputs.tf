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

output "route53_zone_id" {
  description = "Route53 public hosted zone ID for the root domain."
  value       = try(aws_route53_zone.public[0].zone_id, data.aws_route53_zone.selected[0].zone_id, null)
}

output "route53_name_servers" {
  description = "Route53 public hosted zone name servers to configure at the domain registrar."
  value       = try(aws_route53_zone.public[0].name_servers, null)
}

output "app_domain_name" {
  description = "Public DNS name for the BlackTickets web application."
  value       = var.app_domain_name
}

output "app_dns_record_fqdn" {
  description = "Route53 DNS record FQDN for the BlackTickets web application."
  value       = try(aws_route53_record.app[0].fqdn, null)
}

output "app_acm_certificate_arn" {
  description = "ACM certificate ARN for the BlackTickets web application."
  value       = try(aws_acm_certificate.app[0].arn, null)
}
