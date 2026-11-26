# --------------------------------------------------
# SNS Topic for Alertmanager Notifications
# --------------------------------------------------

resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(var.tags, {
    Name      = "${var.project_name}-alerts"
    Component = "observability"
  })
}

# --------------------------------------------------
# Alertmanager Pod Identity IAM Role
# --------------------------------------------------

resource "aws_iam_role" "alertmanager" {
  name = "${var.project_name}-alertmanager-sns-role"

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
          "aws:RequestTag/kubernetes-namespace"       = var.namespace
          "aws:RequestTag/kubernetes-service-account" = var.service_account
          "aws:RequestTag/eks-cluster-arn"            = var.cluster_arn
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Name      = "${var.project_name}-alertmanager-sns-role"
    Component = "observability"
  })
}

# --------------------------------------------------
# Allow Alertmanager to Publish to This SNS Topic
# --------------------------------------------------

# Resolve the AWS-managed SNS KMS key after the encrypted topic exists.
data "aws_kms_alias" "sns" {
  name = "alias/aws/sns"

  depends_on = [
    aws_sns_topic.alerts
  ]
}

resource "aws_iam_role_policy" "alertmanager_publish" {
  name = "${var.project_name}-alertmanager-sns-publish"
  role = aws_iam_role.alertmanager.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Sid      = "PublishAlertNotifications"
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = aws_sns_topic.alerts.arn
      }, {
      Sid    = "UseSNSManagedEncryptionKey"
      Effect = "Allow"

      Action = [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ]

      Resource = data.aws_kms_alias.sns.target_key_arn
    }]
  })
}

# --------------------------------------------------
# EKS Pod Identity Association
# --------------------------------------------------

resource "aws_eks_pod_identity_association" "alertmanager" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account
  role_arn        = aws_iam_role.alertmanager.arn

  depends_on = [
    aws_iam_role_policy.alertmanager_publish
  ]
}

# --------------------------------------------------
# Optional Email Subscription
# --------------------------------------------------

resource "aws_sns_topic_subscription" "email" {
  count = (
    var.email_endpoint != null &&
    trimspace(var.email_endpoint) != ""
  ) ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.email_endpoint
}
