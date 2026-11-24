
output "alb_security_group_id" {
  description = "Security Group ID for the internal API Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "frontend_alb_security_group_id" {
  description = "Security Group ID for the public Frontend Application Load Balancer"
  value       = aws_security_group.frontend_alb.id
}

output "eks_workers_security_group_id" {
  description = "Security Group ID for EKS worker nodes"
  value       = aws_security_group.eks_workers.id
}

output "rds_security_group_id" {
  description = "Security Group ID for PostgreSQL"
  value       = aws_security_group.rds.id
}

output "vpc_endpoints_security_group_id" {
  description = "Security Group ID for VPC interface endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "vpc_link_security_group_id" {
  description = "Security Group ID for API Gateway VPC Link"
  value       = aws_security_group.vpc_link.id
}

