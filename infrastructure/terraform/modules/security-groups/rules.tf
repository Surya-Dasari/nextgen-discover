
# ==================================================
# INGRESS RULES
# ==================================================

# --------------------------------------------------
# 1. EKS Workers - API Service traffic from Internal ALB
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "eks_from_alb" {
  security_group_id = aws_security_group.eks_workers.id

  referenced_security_group_id = aws_security_group.alb.id

  description = "Allow API Service traffic from internal ALB"
  from_port   = 9000
  to_port     = 9000
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 2. EKS Workers - Frontend traffic from Public ALB
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "eks_from_frontend_alb" {
  security_group_id = aws_security_group.eks_workers.id

  referenced_security_group_id = aws_security_group.frontend_alb.id

  description = "Allow frontend traffic from public frontend ALB"
  from_port   = 9080
  to_port     = 9080
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 3. EKS Workers - Node-to-Node Communication
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "eks_workers_self" {
  security_group_id = aws_security_group.eks_workers.id

  referenced_security_group_id = aws_security_group.eks_workers.id

  description = "Allow communication between EKS workers"
  ip_protocol = "-1"
}

# --------------------------------------------------
# 4. RDS - PostgreSQL from EKS Workers
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
# 5. VPC Endpoints - HTTPS from EKS Workers
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_eks" {
  security_group_id = aws_security_group.vpc_endpoints.id

  referenced_security_group_id = aws_security_group.eks_workers.id

  description = "Allow HTTPS from EKS workers"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 6. Internal ALB - HTTP from API Gateway VPC Link
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_from_vpc_link" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = aws_security_group.vpc_link.id

  description = "Allow HTTP only from API Gateway VPC Link"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 7. Public Frontend ALB - HTTP from Internet
# --------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "frontend_alb_http" {
  security_group_id = aws_security_group.frontend_alb.id

  description = "Allow temporary HTTP frontend access"
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}


# ==================================================
# EGRESS RULES
# ==================================================

# --------------------------------------------------
# 8. Internal ALB - Outbound to EKS API Service
# --------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "alb_to_eks" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = aws_security_group.eks_workers.id

  description = "Allow internal ALB traffic to API Service targets"
  from_port   = 9000
  to_port     = 9000
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 9. Public Frontend ALB - Outbound to Frontend Pods
# --------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "frontend_alb_to_eks" {
  security_group_id = aws_security_group.frontend_alb.id

  referenced_security_group_id = aws_security_group.eks_workers.id

  description = "Allow frontend ALB traffic to frontend targets"
  from_port   = 9080
  to_port     = 9080
  ip_protocol = "tcp"
}

# --------------------------------------------------
# 10. EKS Workers - Outbound Connectivity
# --------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "eks_workers_all_outbound" {
  security_group_id = aws_security_group.eks_workers.id

  description = "Allow outbound connectivity for EKS nodes and workloads"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# --------------------------------------------------
# 11. API Gateway VPC Link - Outbound to Internal ALB
# --------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "vpc_link_to_alb" {
  security_group_id = aws_security_group.vpc_link.id

  cidr_ipv4 = var.vpc_cidr

  description = "Allow API Gateway VPC Link to reach internal ALB"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

