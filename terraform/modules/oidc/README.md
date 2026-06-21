# GitHub Actions OIDC

This module creates the AWS IAM trust needed for GitHub Actions to deploy BlackTickets Terraform without static AWS keys.

## What OIDC Is

OIDC lets GitHub Actions request a short-lived identity token from GitHub. AWS STS validates that token against the GitHub IAM OIDC provider and returns temporary AWS credentials for the configured IAM role.

This avoids storing long-lived `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` values in GitHub.

## Trust Relationship

The role trusts:

```text
https://token.actions.githubusercontent.com
```

The trust policy requires:

```text
token.actions.githubusercontent.com:aud = sts.amazonaws.com
token.actions.githubusercontent.com:sub = repo:BlackTickets-Platform/blacktickets-infra:*
```

That allows workflows from the `BlackTickets-Platform/blacktickets-infra` repository to assume the role.

## How To Test

OIDC tokens are normally minted inside GitHub Actions. The practical test is:

1. Apply this module.
2. Copy the `role_arn` output into the GitHub repository secret `AWS_DEPLOY_ROLE_ARN`.
3. Run the Terraform workflow manually with `workflow_dispatch`.

For a raw STS test, you need a valid GitHub OIDC web identity token from a workflow run:

```bash
aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::<account-id>:role/blacktickets-dev-github-terraform-deploy \
  --role-session-name github-actions-oidc-test \
  --web-identity-token "$GITHUB_OIDC_TOKEN" \
  --duration-seconds 900
```

The token cannot be generated from a normal local shell without GitHub's Actions OIDC environment.

## Security Note

This dev module currently grants administrator-style permissions through an inline policy because Terraform needs to create many AWS resource types.

Before production, restrict both:

- `token.actions.githubusercontent.com:sub`
  - Prefer exact branch/environment subjects such as `repo:BlackTickets-Platform/blacktickets-infra:ref:refs/heads/main`.
- IAM permissions
  - Replace the admin policy with least-privilege permissions for Terraform-managed services only.
