locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "eks_cluster" {
  name        = "${local.name_prefix}-eks-cluster-sg"
  description = "Security group for the BlackTickets EKS control plane."
  vpc_id      = var.vpc_id

  ingress {
    description = "Kubernetes API access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.eks_api_ingress_cidrs
  }

  egress {
    description = "Outbound cluster traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eks-cluster-sg"
  })
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Allow PostgreSQL traffic from EKS workloads."
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS cluster security group"
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    description = "Outbound database traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds-sg"
  })
}
