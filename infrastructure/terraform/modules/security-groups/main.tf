
# --------------------------------------------------
# Internal API Application Load Balancer Security Group
# --------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for public Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name}-alb-sg"
    Component = "internal-load-balancer"
  })
}

# --------------------------------------------------
# Public Frontend ALB Security Group
# --------------------------------------------------

resource "aws_security_group" "frontend_alb" {
  name        = "${var.name}-frontend-alb-sg"
  description = "Security group for public Frontend Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name}-frontend-alb-sg"
    Component = "frontend-load-balancer"
  })
}

# --------------------------------------------------
# EKS Worker Nodes Security Group
# --------------------------------------------------

resource "aws_security_group" "eks_workers" {
  name        = "${var.name}-eks-workers-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name}-eks-workers-sg"
    Component = "eks"
  })
}

# --------------------------------------------------
# RDS PostgreSQL Security Group
# --------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for PostgreSQL database"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name}-rds-sg"
    Component = "database"
  })
}

# --------------------------------------------------
# VPC Endpoints Security Group
# --------------------------------------------------

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name}-vpc-endpoints-sg"
  description = "Security group for AWS VPC interface endpoints"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name}-vpc-endpoints-sg"
    Component = "vpc-endpoints"
  })
}

# --------------------------------------------------
# API Gateway VPC Link Security Group
# --------------------------------------------------

resource "aws_security_group" "vpc_link" {
  name        = "${var.name}-vpc-link-sg"
  description = "Security group for API Gateway VPC Link"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name      = "${var.name}-vpc-link-sg"
    Component = "api-gateway-vpc-link"
  })
}

