data "aws_partition" "current" {}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  cluster_arn = "arn:${data.aws_partition.current.partition}:eks:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"

  common_tags = merge(var.tags, {
    Project   = var.project_name
    Component = "karpenter"
    ManagedBy = "Terraform"
  })

}

# --------------------------------------------------
# Karpenter Controller IAM Role - EKS Pod Identity
# --------------------------------------------------

resource "aws_iam_role" "controller" {
  name = "${var.project_name}-karpenter-controller"

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

  tags = local.common_tags
}

# --------------------------------------------------
# Karpenter Node IAM Role
# --------------------------------------------------

resource "aws_iam_role" "node" {
  name = "${var.project_name}-karpenter-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# --------------------------------------------------
# Controller Policy 1: EC2 Node Lifecycle
# --------------------------------------------------

resource "aws_iam_policy" "node_lifecycle" {
  name = "${var.project_name}-karpenter-node-lifecycle"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowScopedEC2InstanceAccessActions"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}::image/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}::snapshot/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:security-group/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:subnet/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:capacity-reservation/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:placement-group/*"
        ]
      },
      {
        Sid    = "AllowScopedEC2LaunchTemplateAccessActions"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:launch-template/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedEC2InstanceActionsWithTags"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:fleet/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:instance/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:volume/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:network-interface/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:launch-template/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:spot-instances-request/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name"                      = var.cluster_name
          }
          StringLike = {
            "aws:RequestTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedResourceCreationTagging"
        Effect = "Allow"
        Action = "ec2:CreateTags"
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:fleet/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:instance/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:volume/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:network-interface/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:launch-template/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:spot-instances-request/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name"                      = var.cluster_name
            "ec2:CreateAction" = [
              "RunInstances",
              "CreateFleet",
              "CreateLaunchTemplate"
            ]
          }
          StringLike = {
            "aws:RequestTag/karpenter.sh/nodepool" = "*"
          }
        }
      },
      {
        Sid      = "AllowScopedResourceTagging"
        Effect   = "Allow"
        Action   = "ec2:CreateTags"
        Resource = "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:instance/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.sh/nodepool" = "*"
          }
          StringEqualsIfExists = {
            "aws:RequestTag/eks:eks-cluster-name" = var.cluster_name
          }
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = [
              "eks:eks-cluster-name",
              "karpenter.sh/nodeclaim",
              "Name"
            ]
          }
        }
      },
      {
        Sid    = "AllowScopedDeletion"
        Effect = "Allow"
        Action = [
          "ec2:TerminateInstances",
          "ec2:RebootInstances",
          "ec2:DeleteLaunchTemplate"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:instance/*",
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:*:launch-template/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Controller Policy 2: IAM Integration
# --------------------------------------------------

resource "aws_iam_policy" "iam_integration" {
  name = "${var.project_name}-karpenter-iam-integration"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowPassingInstanceRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.node.arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "ec2.amazonaws.com.cn"
            ]
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileCreationActions"
        Effect   = "Allow"
        Action   = "iam:CreateInstanceProfile"
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name"                      = var.cluster_name
            "aws:RequestTag/topology.kubernetes.io/region"             = data.aws_region.current.region
          }
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileTagActions"
        Effect   = "Allow"
        Action   = "iam:TagInstanceProfile"
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"             = data.aws_region.current.region
            "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"  = "owned"
            "aws:RequestTag/eks:eks-cluster-name"                       = var.cluster_name
            "aws:RequestTag/topology.kubernetes.io/region"              = data.aws_region.current.region
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileActions"
        Effect = "Allow"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region"             = data.aws_region.current.region
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Controller Policy 3: EKS Integration
# --------------------------------------------------

resource "aws_iam_policy" "eks_integration" {
  name = "${var.project_name}-karpenter-eks-integration"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "eks:DescribeCluster"
      Resource = local.cluster_arn
    }]
  })

  tags = local.common_tags
}

# --------------------------------------------------
# Controller Policy 4: Interruption Queue
# --------------------------------------------------

resource "aws_iam_policy" "interruption" {
  name = "${var.project_name}-karpenter-interruption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:DeleteMessage",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage"
      ]
      Resource = aws_sqs_queue.interruption.arn
    }]
  })

  tags = local.common_tags
}

# --------------------------------------------------
# Controller Policy 5: Zonal Shift
# --------------------------------------------------

resource "aws_iam_policy" "zonal_shift" {
  name = "${var.project_name}-karpenter-zonal-shift"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "arc-zonal-shift:GetManagedResource"
      Resource = "*"
      Condition = {
        StringEquals = {
          "arc-zonal-shift:ResourceIdentifier" = local.cluster_arn
        }
      }
    }]
  })

  tags = local.common_tags
}

# --------------------------------------------------
# Controller Policy 6: Resource Discovery
# --------------------------------------------------

resource "aws_iam_policy" "resource_discovery" {
  name = "${var.project_name}-karpenter-resource-discovery"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRegionalReadActions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeCapacityReservations",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribePlacementGroups",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.region
          }
        }
      },
      {
        Sid      = "AllowSSMReadActions"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.region}::parameter/aws/service/*"
      },
      {
        Sid      = "AllowPricingReadActions"
        Effect   = "Allow"
        Action   = "pricing:GetProducts"
        Resource = "*"
      },
      {
        Sid      = "AllowUnscopedInstanceProfileListAction"
        Effect   = "Allow"
        Action   = "iam:ListInstanceProfiles"
        Resource = "*"
      },
      {
        Sid      = "AllowInstanceProfileReadActions"
        Effect   = "Allow"
        Action   = "iam:GetInstanceProfile"
        Resource = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "controller_policies" {
  for_each = {
    node_lifecycle     = aws_iam_policy.node_lifecycle.arn
    iam_integration    = aws_iam_policy.iam_integration.arn
    eks_integration    = aws_iam_policy.eks_integration.arn
    interruption       = aws_iam_policy.interruption.arn
    zonal_shift        = aws_iam_policy.zonal_shift.arn
    resource_discovery = aws_iam_policy.resource_discovery.arn
  }

  role       = aws_iam_role.controller.name
  policy_arn = each.value
}

# --------------------------------------------------
# EKS Pod Identity Association
# --------------------------------------------------

resource "aws_eks_pod_identity_association" "controller" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "karpenter"
  role_arn        = aws_iam_role.controller.arn
}

# --------------------------------------------------
# EKS Node Access Entry
# --------------------------------------------------

resource "aws_eks_access_entry" "node" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.node.arn
  type          = "EC2_LINUX"
}

# --------------------------------------------------
# SQS Interruption Queue
# --------------------------------------------------

resource "aws_sqs_queue" "interruption" {
  name                       = var.cluster_name
  message_retention_seconds  = 300
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 30

  tags = local.common_tags
}

# --------------------------------------------------
# EventBridge Interruption Rules
# --------------------------------------------------

locals {
  interruption_rules = {
    health = {
      description = "AWS Health events relevant to EC2"
      pattern = {
        source        = ["aws.health"]
        "detail-type" = ["AWS Health Event"]
      }
    }

    spot_interruption = {
      description = "EC2 Spot interruption warnings"
      pattern = {
        source        = ["aws.ec2"]
        "detail-type" = ["EC2 Spot Instance Interruption Warning"]
      }
    }

    rebalance = {
      description = "EC2 instance rebalance recommendations"
      pattern = {
        source        = ["aws.ec2"]
        "detail-type" = ["EC2 Instance Rebalance Recommendation"]
      }
    }

    instance_state = {
      description = "EC2 instance state changes"
      pattern = {
        source        = ["aws.ec2"]
        "detail-type" = ["EC2 Instance State-change Notification"]
      }
    }

    capacity_reservation = {
      description = "EC2 Capacity Reservation interruption warnings"
      pattern = {
        source        = ["aws.ec2"]
        "detail-type" = ["EC2 Capacity Reservation Instance Interruption Warning"]
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "interruption" {
  for_each = local.interruption_rules

  name          = "${var.cluster_name}-${each.key}"
  description   = each.value.description
  event_pattern = jsonencode(each.value.pattern)

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "interruption" {
  for_each = aws_cloudwatch_event_rule.interruption

  rule      = each.value.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.interruption.arn
}

# --------------------------------------------------
# SQS Queue Policy - EventBridge Publishing
# --------------------------------------------------

data "aws_iam_policy_document" "interruption_queue" {
  dynamic "statement" {
    for_each = aws_cloudwatch_event_rule.interruption

    content {
      sid    = "AllowEventBridge${replace(title(statement.key), "_", "")}"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }

      actions   = ["sqs:SendMessage"]
      resources = [aws_sqs_queue.interruption.arn]

      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [statement.value.arn]
      }
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.interruption.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "interruption" {
  queue_url = aws_sqs_queue.interruption.id
  policy    = data.aws_iam_policy_document.interruption_queue.json
}
