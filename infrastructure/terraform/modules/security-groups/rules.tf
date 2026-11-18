
# ==================================================
# INGRESS RULES
# ==================================================

# --------------------------------------------------
# 1. ALB - Public HTTP
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id

  description = "Allow HTTP from approved IPv4 CIDRs"
  cidr_ipv4   = each.value
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 2. ALB - Public HTTPS
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.alb_ingress_cidrs)

  security_group_id = aws_security_group.alb.id

  description = "Allow HTTPS from approved IPv4 CIDRs"
  cidr_ipv4   = each.value
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 3. EKS Workers - Traffic from ALB
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "eks_from_alb" {
  security_group_id = aws_security_group.eks_workers.id

  referenced_security_group_id = aws_security_group.alb.id

  description = "Allow application traffic from ALB"
  from_port   = 9080
  to_port     = 9080
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 4. EKS Workers - Node-to-Node Communication
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "eks_workers_self" {
  security_group_id = aws_security_group.eks_workers.id

  referenced_security_group_id = aws_security_group.eks_workers.id

  description = "Allow communication between EKS workers"
  ip_protocol = "-1"
}

# --------------------------------------------------
# 5. RDS - PostgreSQL from EKS Workers
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.eks_workers.id

  description = "Allow PostgreSQL from EKS workers"
  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 6. VPC Endpoints - HTTPS from EKS Workers
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_eks" {
  security_group_id = aws_security_group.vpc_endpoints.id

  referenced_security_group_id = aws_security_group.eks_workers.id

  description = "Allow HTTPS from EKS workers"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}


# ==================================================
# EGRESS RULES
# ==================================================

# --------------------------------------------------
# 7. ALB - Outbound to EKS Workers
# --------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "alb_to_eks" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = aws_security_group.eks_workers.id

  description = "Allow ALB traffic to EKS application targets"
  from_port   = 9080
  to_port     = 9080
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 8. EKS Workers - Outbound Connectivity
# --------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "eks_workers_all_outbound" {
  security_group_id = aws_security_group.eks_workers.id

  description = "Allow outbound connectivity for EKS nodes and workloads"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# VPC Link -> Private ALB (HTTP)
resource "aws_vpc_security_group_egress_rule" "vpc_link_to_alb" {
  security_group_id            = aws_security_group.vpc_link.id
  referenced_security_group_id = aws_security_group.alb.id

  description = "Allow API Gateway VPC Link to reach private ALB"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# Private ALB <- VPC Link (HTTP)
resource "aws_vpc_security_group_ingress_rule" "alb_from_vpc_link" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.vpc_link.id

  description = "Allow HTTP from API Gateway VPC Link"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}
