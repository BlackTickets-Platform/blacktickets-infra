terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "blacktickets-dev-tfstate"
    key            = "blacktickets/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "blacktickets-dev-terraform-locks"
    encrypt        = true
  }

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
