# ==================================================
# CURRENT AWS ACCOUNT AND REGION
# ==================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


# ==================================================
# CLOUDWATCH LOG GROUP
# ==================================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name      = "${var.name}-flow-logs"
    Component = "network-monitoring"
  })
}


# ==================================================
# IAM ROLE FOR VPC FLOW LOGS
# ==================================================

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }

      Action = "sts:AssumeRole"

      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }

        ArnLike = {
          "aws:SourceArn" = "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Name      = "${var.name}-flow-logs-role"
    Component = "network-monitoring"
  })
}


# ==================================================
# IAM POLICY
# ==================================================

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.name}-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]

      Resource = "*"
    }]
  })
}


# ==================================================
# VPC FLOW LOGS
# ==================================================

resource "aws_flow_log" "vpc" {
  vpc_id               = var.vpc_id
  traffic_type         = var.traffic_type
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn

  depends_on = [
    aws_iam_role_policy.vpc_flow_logs
  ]

  tags = merge(var.tags, {
    Name      = "${var.name}-vpc-flow-logs"
    Component = "network-monitoring"
  })
}
