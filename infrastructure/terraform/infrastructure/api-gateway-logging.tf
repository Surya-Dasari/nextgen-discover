# --------------------------------------------------
# API Gateway Regional CloudWatch Logging Configuration
# --------------------------------------------------

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = module.iam.api_gateway_cloudwatch_role_arn

  depends_on = [
    module.iam
  ]
}
