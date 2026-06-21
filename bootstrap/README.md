# Terraform Backend Bootstrap

This folder creates the one-time Terraform backend resources for BlackTickets:

- S3 bucket: `blacktickets-dev-tfstate`
- DynamoDB lock table: `blacktickets-dev-terraform-locks`

The main Terraform project in `../terraform` uses these resources for remote state.

## How To Run

```powershell
cd D:\project\blacktickets-final\blacktickets-infra\bootstrap
terraform init
terraform plan
terraform apply
```

## Warning

Run only once. After this, delete this folder or guard it with a separate state file.

Do not add a remote backend to this bootstrap configuration. It intentionally uses local state so it can create the backend infrastructure itself.

## Verify

```powershell
aws s3 ls | Select-String blacktickets-dev-tfstate
aws dynamodb list-tables --region us-east-1 | Select-String blacktickets-dev-terraform-locks
aws s3api get-bucket-versioning --bucket blacktickets-dev-tfstate
aws s3api get-bucket-encryption --bucket blacktickets-dev-tfstate
aws s3api get-public-access-block --bucket blacktickets-dev-tfstate
```
