data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  service_names = [
    "frontend",
    "identity-service",
    "event-service",
    "booking-service",
    "chatbot-service"
  ]
}

module "networking" {
  source = "./modules/networking"

  project_name             = var.project_name
  environment              = var.environment
  eks_cluster_name         = local.name_prefix
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

module "security" {
  source = "./modules/security"

  project_name             = var.project_name
  environment              = var.environment
  vpc_id                   = module.networking.vpc_id
  eks_api_ingress_cidrs    = var.eks_api_ingress_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  rds_port                 = var.rds_port
}

module "ecr" {
  source = "./modules/ecr"

  project_name  = var.project_name
  environment   = var.environment
  service_names = local.service_names
}

module "data" {
  source = "./modules/data"

  project_name          = var.project_name
  environment           = var.environment
  private_db_subnet_ids = module.networking.private_db_subnet_ids
  rds_security_group_id = module.security.rds_security_group_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
  rds_port              = var.rds_port
  poster_bucket_name    = var.poster_bucket_name
  notification_email    = var.notification_email
}

module "eks" {
  source = "./modules/eks"

  project_name              = var.project_name
  environment               = var.environment
  cluster_name              = local.name_prefix
  cluster_version           = var.eks_cluster_version
  subnet_ids                = module.networking.private_app_subnet_ids
  cluster_security_group_id = module.security.eks_cluster_security_group_id
  node_instance_types       = var.eks_node_instance_types
  node_desired_size         = var.eks_node_desired_size
  node_min_size             = var.eks_node_min_size
  node_max_size             = var.eks_node_max_size
}

module "irsa" {
  source = "./modules/irsa"

  project_name                    = var.project_name
  environment                     = var.environment
  aws_region                      = var.aws_region
  account_id                      = data.aws_caller_identity.current.account_id
  oidc_provider_arn               = module.eks.oidc_provider_arn
  oidc_provider_url               = module.eks.oidc_provider_url
  namespace                       = "${var.project_name}-${var.environment}"
  poster_bucket_arn               = module.data.poster_bucket_arn
  booking_notifications_queue_arn = module.data.booking_notifications_queue_arn
  bedrock_model_arn               = "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.nova-micro-v1:0"
}

module "edge" {
  source = "./modules/edge"

  project_name          = var.project_name
  environment           = var.environment
  poster_bucket_id      = module.data.poster_bucket_name
  poster_bucket_arn     = module.data.poster_bucket_arn
  poster_bucket_domain  = module.data.poster_bucket_regional_domain_name
  domain_name           = var.domain_name
  create_route53_record = var.create_route53_record
}

module "observability" {
  source = "./modules/observability"

  project_name                      = var.project_name
  environment                       = var.environment
  aws_region                        = var.aws_region
  account_id                        = data.aws_caller_identity.current.account_id
  eks_cluster_name                  = module.eks.cluster_name
  rds_instance_identifier           = module.data.rds_instance_identifier
  lambda_function_name              = module.data.booking_notification_lambda_name
  sqs_queue_name                    = module.data.booking_notifications_queue_name
  sns_topic_arn                     = module.data.booking_notifications_sns_topic_arn
  poster_cloudfront_distribution_id = module.edge.poster_cloudfront_distribution_id
  poster_bucket_arn                 = module.data.poster_bucket_arn
}
