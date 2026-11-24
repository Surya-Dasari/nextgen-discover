
data "archive_file" "authorizer" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/authorizer.zip"
}

# --------------------------------------------------
# Lambda Execution Role
# --------------------------------------------------

resource "aws_iam_role" "lambda_authorizer" {
  name = "${var.project_name}-lambda-authorizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# --------------------------------------------------
# CloudWatch Log Group
# --------------------------------------------------

resource "aws_cloudwatch_log_group" "authorizer" {
  name              = "/aws/lambda/${var.project_name}-jwt-authorizer"
  retention_in_days = 30

  tags = var.tags
}

# --------------------------------------------------
# Lambda Logging Permissions
# --------------------------------------------------

resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.project_name}-lambda-authorizer-logging"
  role = aws_iam_role.lambda_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.authorizer.arn}:*"
    }]
  })
}

# --------------------------------------------------
# JWT Lambda Authorizer
# --------------------------------------------------

resource "aws_lambda_function" "authorizer" {
  function_name = "${var.project_name}-jwt-authorizer"
  description   = "RS256 JWT authorizer for NextGen Discover API Gateway"

  role             = aws_iam_role.lambda_authorizer.arn
  runtime          = "nodejs24.x"
  handler          = "index.handler"
  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256

  memory_size = 128
  timeout     = 5

  environment {
    variables = {
      JWT_PUBLIC_KEY = var.jwt_public_key_pem
      JWT_ISSUER     = var.jwt_issuer
      JWT_AUDIENCE   = var.jwt_audience
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_logging,
    aws_cloudwatch_log_group.authorizer
  ]

  tags = var.tags
}

