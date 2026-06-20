output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster security group."
  value       = aws_security_group.eks_cluster.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.rds.id
}
