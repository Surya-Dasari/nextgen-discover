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
# Application Database Credential Secret Containers
# --------------------------------------------------

data "aws_secretsmanager_secret" "catalogue_db_credentials" {
  name = "${var.project_name}/catalogue/db-credentials"
}

resource "aws_secretsmanager_secret" "userservice_db_credentials" {
  name        = "${var.project_name}/userservice/db-credentials"
  description = "User Service PostgreSQL credentials"

  tags = {
    Project   = var.project_name
    Component = "userservice-database"
    ManagedBy = "Terraform"
  }
}

resource "aws_secretsmanager_secret" "notificationservice_db_credentials" {
  name        = "${var.project_name}/notificationservice/db-credentials"
  description = "Notification Service PostgreSQL credentials"

  tags = {
    Project   = var.project_name
    Component = "notificationservice-database"
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

        Resource = [
          module.rds.master_user_secret_arn,
          data.aws_secretsmanager_secret.catalogue_db_credentials.arn,
          aws_secretsmanager_secret.userservice_db_credentials.arn,
          aws_secretsmanager_secret.notificationservice_db_credentials.arn
        ]
      },
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:PutSecretValue"
        ]

        Resource = [
          aws_secretsmanager_secret.userservice_db_credentials.arn,
          aws_secretsmanager_secret.notificationservice_db_credentials.arn
        ]
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
