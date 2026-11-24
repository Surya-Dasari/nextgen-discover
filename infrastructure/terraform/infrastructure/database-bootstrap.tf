# --------------------------------------------------
# NextGen Discover Database Bootstrap - IAM Role
# --------------------------------------------------

resource "aws_iam_role" "database_bootstrap" {
  name = "${var.project_name}-database-bootstrap-role"

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

      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }

        ArnEquals = {
          "aws:SourceArn" = module.eks.cluster_arn
        }
      }
    }]
  })

  tags = {
    Project   = var.project_name
    Component = "database-bootstrap"
    ManagedBy = "Terraform"
  }
}

# --------------------------------------------------
# Secrets Manager and KMS Permissions
# --------------------------------------------------

resource "aws_iam_role_policy" "database_bootstrap" {
  name = "${var.project_name}-database-bootstrap-policy"
  role = aws_iam_role.database_bootstrap.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = module.rds.master_user_secret_arn
      },
      {
        Effect = "Allow"

        Action = [
          "kms:Decrypt"
        ]

        Resource = module.kms.kms_key_arn

        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# --------------------------------------------------
# EKS Pod Identity Association
# --------------------------------------------------

resource "aws_eks_pod_identity_association" "database_bootstrap" {
  cluster_name    = module.eks.cluster_name
  namespace       = "nextgen-discover"
  service_account = "database-bootstrap"
  role_arn        = aws_iam_role.database_bootstrap.arn

  depends_on = [
    module.eks,
    aws_iam_role_policy.database_bootstrap
  ]
}

# --------------------------------------------------
# Database Bootstrap Helm Release
# --------------------------------------------------

resource "helm_release" "database_bootstrap" {
  name      = "database-bootstrap"
  chart     = "${path.module}/../../helm/db-bootstrap"
  namespace = "nextgen-discover"

  create_namespace = true

  atomic          = true
  cleanup_on_fail = true
  timeout         = 600
  wait            = true
  wait_for_jobs   = true

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "database-bootstrap"
      }

      image = {
        repository = module.ecr.repository_urls["database-bootstrap"]
        tag        = "1.0.0"
        pullPolicy = "IfNotPresent"
      }

      aws = {
        region    = var.aws_region
        secretArn = module.rds.master_user_secret_arn
      }

      database = {
        host               = module.rds.db_address
        port               = module.rds.db_port
        adminDatabase      = "postgres"
        names              = ["nextgendiscover", "nextgendiscover_catalogue"]
        instanceGeneration = module.rds.db_resource_id
      }
    })
  ]

  depends_on = [
    module.eks,
    aws_eks_pod_identity_association.database_bootstrap
  ]
}
