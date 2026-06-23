# Development non-secret Terraform values.
# Keep passwords, tokens, JWT secrets, and credentials out of this file.
# CI passes db_password from GitHub Secrets as TF_VAR_db_password.

aws_region   = "us-east-1"
project_name = "blacktickets"
environment  = "dev"

vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidrs      = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
private_db_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]

cluster_name        = "blacktickets-dev"
eks_cluster_version = "1.31"

eks_api_ingress_cidrs   = ["0.0.0.0/0"]
eks_node_instance_types = ["t3.medium"]
eks_node_desired_size   = 3
eks_node_min_size       = 1
eks_node_max_size       = 4

db_name              = "blacktickets"
db_username          = "postgres"
db_instance_class    = "db.t4g.micro"
db_allocated_storage = 20
rds_port             = 5432

poster_bucket_name    = "blacktickets-dev-posters"
notification_email    = "ananthakkumarv@gmail.com"
domain_name           = "ananthapps.site"
app_domain_name       = "blacktickets.ananthapps.site"
create_route53_zone   = true
create_route53_record = true

bedrock_assume_role_arn    = null
app_load_balancer_dns_name = "k8s-blacktic-blacktic-3ca4ae07e3-958477236.us-east-1.elb.amazonaws.com"
