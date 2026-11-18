
# --------------------------------------------------
# VPC Outputs
# --------------------------------------------------

output "vpc_id" {
  description = "ID of the NextGen Discover VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# --------------------------------------------------
# Subnet Outputs
# --------------------------------------------------

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value = {
    for key, subnet in aws_subnet.this :
    key => subnet.id
    if local.subnets[key].tier == "public"
  }
}

output "private_app_subnet_ids" {
  description = "IDs of private application subnets"
  value = {
    for key, subnet in aws_subnet.this :
    key => subnet.id
    if local.subnets[key].tier == "private-app"
  }
}

output "private_db_subnet_ids" {
  description = "IDs of private database subnets"
  value = {
    for key, subnet in aws_subnet.this :
    key => subnet.id
    if local.subnets[key].tier == "private-db"
  }
}

output "eks_control_plane_subnet_ids" {
  description = "IDs of dedicated EKS cluster subnets"
  value = {
    for key, subnet in aws_subnet.this :
    key => subnet.id
    if local.subnets[key].tier == "eks-control-plane"
  }
}

# --------------------------------------------------
# Networking Outputs
# --------------------------------------------------

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways by Availability Zone"
  value = {
    for key, nat in aws_nat_gateway.this :
    key => nat.id
  }
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "Private application route table IDs by AZ"
  value = {
    for key, route_table in aws_route_table.private_app :
    key => route_table.id
  }
}

output "private_db_route_table_id" {
  description = "ID of the isolated database route table"
  value       = aws_route_table.private_db.id
}

output "eks_control_plane_route_table_id" {
  description = "ID of the EKS control-plane route table"
  value       = aws_route_table.eks_control_plane.id
}
