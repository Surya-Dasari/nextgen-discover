
# --------------------------------------------------
# EKS Cluster IAM Role
# --------------------------------------------------

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "eks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name      = "${var.project_name}-eks-cluster-role"
    Component = "EKS"
  })
}

# --------------------------------------------------
# EKS Worker Node IAM Role
# --------------------------------------------------

resource "aws_iam_role" "eks_node" {
  name = "${var.project_name}-eks-node-role"

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

  tags = merge(var.tags, {
    Name      = "${var.project_name}-eks-node-role"
    Component = "EKS"
  })
}

# --------------------------------------------------
# API Gateway CloudWatch Logging Role
# --------------------------------------------------

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.project_name}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "apigateway.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name      = "${var.project_name}-api-gateway-cloudwatch-role"
    Component = "API Gateway"
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role = aws_iam_role.api_gateway_cloudwatch.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
