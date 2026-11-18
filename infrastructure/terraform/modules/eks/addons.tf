# --------------------------------------------------
# VPC CNI IAM Role
# --------------------------------------------------

resource "aws_iam_role" "vpc_cni" {
  name = "${var.project_name}-eks-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "pods.eks.amazonaws.com"
      }

      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })

  tags = merge(var.tags, {
    Name      = "${var.project_name}-eks-vpc-cni-role"
    Component = "EKS"
  })
}

# --------------------------------------------------
# VPC CNI IAM Policy Attachment
# --------------------------------------------------

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# --------------------------------------------------
# EKS Pod Identity Agent
# --------------------------------------------------

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"

  tags = var.tags
}

# --------------------------------------------------
# EKS VPC CNI Add-on
# --------------------------------------------------

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  pod_identity_association {
    role_arn        = aws_iam_role.vpc_cni.arn
    service_account = "aws-node"
  }

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.vpc_cni
  ]

  tags = var.tags
}

# --------------------------------------------------
# EKS CoreDNS Add-on
# --------------------------------------------------

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = var.tags
}

# --------------------------------------------------
# EKS kube-proxy Add-on
# --------------------------------------------------

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main
  ]

  tags = var.tags
}

# --------------------------------------------------
# EBS CSI Driver IAM Role - EKS Pod Identity
# --------------------------------------------------

resource "aws_iam_role" "ebs_csi" {
  name = "${var.project_name}-eks-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "pods.eks.amazonaws.com"
      }

      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })

  tags = merge(var.tags, {
    Name      = "${var.project_name}-eks-ebs-csi-role"
    Component = "EKS"
  })
}

# --------------------------------------------------
# EBS CSI Driver IAM Policy
# --------------------------------------------------

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role = aws_iam_role.ebs_csi.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
}

# --------------------------------------------------
# AWS EBS CSI Driver Managed Add-on
# --------------------------------------------------

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  pod_identity_association {
    role_arn        = aws_iam_role.ebs_csi.arn
    service_account = "ebs-csi-controller-sa"
  }

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.ebs_csi
  ]

  tags = var.tags
}


# --------------------------------------------------
# AWS Load Balancer Controller IAM Role
# --------------------------------------------------

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.project_name}-eks-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "pods.eks.amazonaws.com"
      }

      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })

  tags = merge(var.tags, {
    Name      = "${var.project_name}-eks-load-balancer-controller-role"
    Component = "EKS"
  })
}

# --------------------------------------------------
# AWS Load Balancer Controller IAM Policy
# --------------------------------------------------

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.project_name}-eks-load-balancer-controller-policy"
  description = "Permissions for AWS Load Balancer Controller"

  policy = file(
    "${path.module}/aws-load-balancer-controller-iam-policy.json"
  )

  tags = merge(var.tags, {
    Name      = "${var.project_name}-eks-load-balancer-controller-policy"
    Component = "EKS"
  })
}

# --------------------------------------------------
# Attach IAM Policy
# --------------------------------------------------

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

# --------------------------------------------------
# EKS Pod Identity Association
# --------------------------------------------------

resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_load_balancer_controller.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}

