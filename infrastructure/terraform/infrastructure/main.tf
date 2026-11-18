
# --------------------------------------------------
# NextGen Discover VPC Module
# --------------------------------------------------

module "vpc" {
  source = "../modules/vpc"

  name     = "${var.project_name}-vpc"
  vpc_cidr = "10.0.0.0/16"

  availability_zone_ids = [
    "use2-az1",
    "use2-az2",
    "use2-az3"
  ]

  public_subnet_cidrs = [
    "10.0.0.0/20",
    "10.0.16.0/20",
    "10.0.32.0/20"
  ]

  private_app_subnet_cidrs = [
    "10.0.64.0/20",
    "10.0.80.0/20",
    "10.0.96.0/20"
  ]

  private_db_subnet_cidrs = [
    "10.0.128.0/24",
    "10.0.129.0/24",
    "10.0.130.0/24"
  ]

  eks_control_plane_subnet_cidrs = [
    "10.0.144.0/27",
    "10.0.144.32/27",
    "10.0.144.64/27"
  ]

  tags = {
    Project = var.project_name
  }
}

# --------------------------------------------------
# NextGen Discover Security Groups Module
# --------------------------------------------------

module "security_groups" {
  source = "../modules/security-groups"

  name   = "${var.project_name}-sg"
  vpc_id = module.vpc.vpc_id

  alb_ingress_cidrs = []

  tags = {
    Project = var.project_name
  }
}

# --------------------------------------------------
# NextGen Discover VPC Flow Logs Module
# --------------------------------------------------

module "vpc_flow_logs" {
  source = "../modules/vpc-flow-logs"

  name   = "${var.project_name}-vpc"
  vpc_id = module.vpc.vpc_id

  traffic_type       = "ALL"
  log_retention_days = 30

  tags = {
    Project = var.project_name
  }
}

# --------------------------------------------------
# NextGen Discover EKS IAM Module
# --------------------------------------------------

module "iam" {
  source = "../modules/iam"

  project_name = var.project_name

  tags = {
    Project = var.project_name
  }
}


# --------------------------------------------------
# NextGen Discover KMS Module
# --------------------------------------------------

module "kms" {
  source = "../modules/kms"

  project_name = var.project_name

  description             = "NextGen Discover encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Project = var.project_name
  }
}


# --------------------------------------------------
# NextGen Discover ECR Module
# --------------------------------------------------

module "ecr" {
  source = "../modules/ecr"

  project_name = var.project_name

  repository_names = [
    "frontend",
    "gateway",
    "api",
    "auth",
    "user",
    "catalogue"
  ]

  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true

  kms_key_arn = module.kms.kms_key_arn

  tags = {
    Project = var.project_name
  }
}


# --------------------------------------------------
# NextGen Discover EKS Module
# --------------------------------------------------

module "eks" {
  source = "../modules/eks"

  project_name = var.project_name

  cluster_version = "1.37"

  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  cluster_subnet_ids = values(module.vpc.eks_control_plane_subnet_ids)
  node_subnet_ids    = values(module.vpc.private_app_subnet_ids)

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Restrict to your trusted public IP/CIDR before deployment.
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  worker_security_group_id = module.security_groups.eks_workers_security_group_id

  node_instance_types = ["c7i-flex.large"]
  node_capacity_type  = "ON_DEMAND"

  node_min_size     = 1
  node_desired_size = 2
  node_max_size     = 3
  node_disk_size    = 30

  tags = {
    Project = var.project_name
  }

  depends_on = [
    module.iam
  ]
}


# --------------------------------------------------
# NextGen Discover RDS PostgreSQL
# --------------------------------------------------

module "rds" {
  source = "../modules/rds"

  db_identifier   = "${var.project_name}-postgres"
  db_name         = "nextgendiscover"
  master_username = "dbadmin"

  engine_version = "17.11"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  subnet_ids = values(module.vpc.private_db_subnet_ids)

  vpc_security_group_ids = [
    module.security_groups.rds_security_group_id
  ]

  kms_key_arn = module.kms.kms_key_arn

  backup_retention_period = 1

  multi_az            = false
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Project   = var.project_name
    Component = "database"
  }
}

# --------------------------------------------------
# NextGen Discover API Gateway and AWS WAF
# --------------------------------------------------

module "api_gateway_waf" {
  source = "../modules/api-gateway-waf"

  project_name = var.project_name

  private_subnet_ids = values(module.vpc.private_app_subnet_ids)

  vpc_link_security_group_id = module.security_groups.vpc_link_security_group_id

  tags = {
    Project   = var.project_name
    Component = "api-security"
  }
}
