output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private EKS/application subnets."
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets."
  value       = aws_subnet.private_db[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway used by private application subnets."
  value       = aws_nat_gateway.main.id
}
