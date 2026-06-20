# BlackTickets Infra

This repository will contain Terraform for the full BlackTickets AWS platform.

Planned infrastructure:

- VPC and networking
- EKS cluster and node groups
- ECR repositories
- RDS, S3, SQS, and related data services
- IAM Roles for Service Accounts (IRSA)
- Security groups, WAF, CloudFront, and Route53
- Observability resources

The scaffold intentionally uses the local Terraform backend for now. This avoids daily AWS cleanup or missing backend resources blocking state access during capstone preparation. The backend can be migrated to S3 later when the final AWS account resources are stable.
