# --------------------------------------------------
# NextGen Discover EKS Cluster
# --------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-eks"
  version  = var.cluster_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids = var.cluster_subnet_ids

    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access

    public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = merge(var.tags, {
    Name      = "${var.project_name}-eks"
    Component = "EKS"
  })
}

# --------------------------------------------------
# EKS Managed Node Group
# --------------------------------------------------

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-workers"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.node_subnet_ids

  instance_types = var.node_instance_types
  capacity_type  = var.node_capacity_type

  launch_template {
    id      = aws_launch_template.workers.id
    version = aws_launch_template.workers.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    Project = var.project_name
    Role    = "worker"
  }

  tags = merge(var.tags, {
    Name      = "${var.project_name}-workers"
    Component = "EKS"
  })

  # Configure the CNI and its Pod Identity association
  # before provisioning EC2 worker nodes.
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
}

# --------------------------------------------------
# EKS Cluster Administrator Access
# --------------------------------------------------

resource "aws_eks_access_entry" "cluster_admin" {
  for_each = var.cluster_admin_principal_arns

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  for_each = aws_eks_access_entry.cluster_admin

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value.principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# --------------------------------------------------
# EKS Observability Managed Node Group
# --------------------------------------------------

resource "aws_eks_node_group" "observability" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-observability-workers"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.node_subnet_ids

  instance_types = var.observability_node_instance_types
  capacity_type  = "ON_DEMAND"

  launch_template {
    id      = aws_launch_template.observability_workers.id
    version = aws_launch_template.observability_workers.latest_version
  }

  scaling_config {
    desired_size = var.observability_node_desired_size
    min_size     = var.observability_node_min_size
    max_size     = var.observability_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    Project  = var.project_name
    Role     = "observability"
    workload = "observability"
  }

  taint {
    key    = "dedicated"
    value  = "observability"
    effect = "NO_SCHEDULE"
  }

  tags = merge(var.tags, {
    Name      = "${var.project_name}-observability-workers"
    Component = "EKS-Observability"
  })

  depends_on = [
    aws_eks_addon.vpc_cni
  ]
}
