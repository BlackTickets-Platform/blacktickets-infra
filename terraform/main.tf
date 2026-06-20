locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "networking" {
  source = "./modules/networking"
}

module "eks" {
  source = "./modules/eks"
}

module "ecr" {
  source = "./modules/ecr"
}

module "data" {
  source = "./modules/data"
}

module "irsa" {
  source = "./modules/irsa"
}

module "security" {
  source = "./modules/security"
}

module "edge" {
  source = "./modules/edge"
}

module "observability" {
  source = "./modules/observability"
}
