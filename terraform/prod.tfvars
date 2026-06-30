# Production Terraform values for BlackTickets.
# Keep credentials, secrets, and master passwords out of this file.

aws_region   = "us-east-1"
project_name = "blacktickets"
environment  = "prod"

# Distinct CIDR block to prevent VPC overlap with Dev environment
vpc_cidr                 = "10.1.0.0/16"
public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24"]
private_app_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
private_db_subnet_cidrs  = ["10.1.21.0/24", "10.1.22.0/24"]

cluster_name        = "blacktickets-prod"
eks_cluster_version = "1.31"

eks_api_ingress_cidrs   = ["0.0.0.0/0"]
eks_node_instance_types = ["t3.large"]
eks_node_desired_size   = 3
eks_node_min_size       = 2
eks_node_max_size       = 5

db_name              = "blacktickets"
db_username          = "postgres"
db_instance_class    = "db.t4g.small"
db_allocated_storage = 50
rds_port             = 5432

poster_bucket_name    = "blacktickets-prod-posters"
notification_email    = "ananthakkumarv@gmail.com"
domain_name           = "ananthapps.site"
app_domain_name       = "blacktickets-prod.ananthapps.site"

# Re-use the existing Route 53 Zone created in the dev env (do not duplicate)
create_route53_zone   = false
create_route53_record = true

# Bedrock configuration
bedrock_assume_role_arn    = "arn:aws:iam::091869721157:role/BlackticketsBedrockCrossAccountRole"
app_load_balancer_dns_name = ""
