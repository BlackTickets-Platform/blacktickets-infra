# Terraform GitHub Actions Setup

This repo uses GitHub Actions with AWS OIDC to run Terraform from the `terraform/` folder.

GitHub exchanges a short-lived OIDC token for an AWS role session. No long-lived AWS access keys are required in GitHub.

## Required GitHub Secret

Create this repository secret:

| Secret | Purpose |
| --- | --- |
| `AWS_DEPLOY_ROLE_ARN` | ARN of the AWS IAM role GitHub Actions can assume through OIDC. |
| `DB_PASSWORD` | PostgreSQL master password passed to Terraform as `TF_VAR_db_password`. |

## Required GitHub Variables

Create these repository variables:

| Variable | Example |
| --- | --- |
| `POSTER_BUCKET_NAME` | `blacktickets-dev-posters` |
| `NOTIFICATION_EMAIL` | `ops@example.com` |
| `DOMAIN_NAME` | `ananthapps.site` |

Leave `DOMAIN_NAME` empty only if Route53 records are disabled.

## Required GitHub Environment

Create a GitHub environment named:

```text
production
```

Recommended settings:

- Required reviewers enabled
- Deployment branches restricted to `main`

Important: this workflow attaches the `production` environment to the Terraform job. If required reviewers are enabled, GitHub may request approval before the job runs.

## AWS OIDC Role Setup

Create an IAM OIDC provider for GitHub if your AWS account does not already have one:

```text
Provider URL: https://token.actions.githubusercontent.com
Audience: sts.amazonaws.com
```

Create an IAM role, for example:

```text
blacktickets-dev-github-terraform-deploy
```

Sample trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::091869721157:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:BlackTickets-Platform/blacktickets-infra:ref:refs/heads/main",
            "repo:BlackTickets-Platform/blacktickets-infra:pull_request"
          ]
        }
      }
    }
  ]
}
```

Attach permissions that allow Terraform to manage the BlackTickets infrastructure:

- VPC, subnets, NAT, routes, and security groups
- EKS, node groups, IAM roles, IAM policies, and OIDC providers
- ECR repositories and lifecycle policies
- RDS, S3, SQS, SNS, Lambda, CloudWatch, CloudTrail, WAF, CloudFront, Route53
- S3 backend bucket access
- DynamoDB state lock table access

For a capstone/lab project, an administrator policy may be acceptable temporarily. For production, replace that with a least-privilege Terraform deployment policy.

## Backend

The Terraform backend is configured in `terraform/provider.tf`:

```text
bucket: blacktickets-dev-tfstate
key: blacktickets/dev/terraform.tfstate
region: us-east-1
dynamodb_table: blacktickets-dev-terraform-locks
encrypt: true
```

Run the `bootstrap/` Terraform once before using this workflow so the backend bucket and lock table exist.

## Workflow Behavior

- Pull requests to `main`: init, fmt, validate, plan, and comment the plan.
- Push to `main`: init, fmt, validate, plan, apply, and publish outputs to the job summary.
- Manual dispatch: init, fmt, validate, and plan.

## Region Note

The current BlackTickets dev deployment is in `us-east-1`, and the backend is also in `us-east-1`.

If you move workloads to another region, update:

- `AWS_REGION`
- `TF_VAR_aws_region`
- Terraform backend region only if the backend bucket/table also move
