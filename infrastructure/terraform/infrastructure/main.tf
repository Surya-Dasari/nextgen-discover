# Retrieve the JWT public key from AWS Secrets Manager.
data "aws_secretsmanager_secret_version" "jwt" {
  secret_id = "nextgen-discover/jwt"
}

locals {
  jwt_public_key_pem = jsondecode(
    data.aws_secretsmanager_secret_version.jwt.secret_string
  )["jwt_public_key_pem"]
}


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

  name     = "${var.project_name}-sg"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr

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

  project_name        = var.project_name
  ecr_repository_arns = module.ecr.repository_arns

  github_owner         = var.github_owner
  github_owner_id      = var.github_owner_id
  github_repository    = var.github_repository
  github_repository_id = var.github_repository_id
  github_branch        = var.github_branch

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
    "api",
    "auth",
    "user",
    "notification",
    "catalogue",
    "database-bootstrap"
  ]

  image_tag_mutability = "MUTABLE"
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

  cluster_version              = "1.37"
  cluster_admin_principal_arns = local.eks_admin_principal_arns

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

  node_min_size     = 3
  node_desired_size = 4
  node_max_size     = 5
  node_disk_size    = 30

  # Dedicated observability worker group
  observability_node_instance_types = ["m7i-flex.large"]
  observability_node_min_size       = 1
  observability_node_desired_size   = 2
  observability_node_max_size       = 2
  observability_node_disk_size      = 30

  tags = {
    Project = var.project_name
  }

  depends_on = [
    module.iam
  ]
}

# Additional EKS administrator identities are supplied through Terraform variables.
locals {
  eks_admin_principal_arns = var.additional_eks_admin_principal_arns
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
# NextGen Discover JWT Lambda Authorizer
# --------------------------------------------------

module "lambda_authorizer" {
  source = "../modules/lambda-authorizer"

  project_name       = var.project_name
  jwt_public_key_pem = local.jwt_public_key_pem
  jwt_issuer         = var.jwt_issuer
  jwt_audience       = var.jwt_audience

  tags = {
    Project   = var.project_name
    Component = "jwt-authorizer"
  }
}

# --------------------------------------------------
# NextGen Discover API Gateway and AWS WAF
# --------------------------------------------------
module "api_gateway_waf" {
  source = "../modules/api-gateway-waf"

  project_name = var.project_name

  enable_api_integrations = var.enable_api_integrations

  lambda_authorizer_function_arn = module.lambda_authorizer.lambda_function_arn
  lambda_authorizer_invoke_arn   = module.lambda_authorizer.lambda_invoke_arn
  private_subnet_ids             = values(module.vpc.private_app_subnet_ids)
  api_alb_arn                    = var.api_alb_arn
  api_alb_dns_name               = var.api_alb_dns_name

  vpc_link_security_group_id = module.security_groups.vpc_link_security_group_id

  tags = {
    Project   = var.project_name
    Component = "api-security"
  }

  depends_on = [
    aws_api_gateway_account.main
  ]
}
