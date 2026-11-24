
output "rest_api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "rest_api_execution_arn" {
  description = "API Gateway REST API execution ARN"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "rest_api_root_resource_id" {
  description = "API Gateway root resource ID"
  value       = aws_api_gateway_rest_api.main.root_resource_id
}

output "web_acl_arn" {
  description = "AWS WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "stage_name" {
  description = "API Gateway deployment stage"
  value       = var.enable_api_integrations ? aws_api_gateway_stage.main[0].stage_name : null
}

output "invoke_url" {
  description = "API Gateway stage invoke URL"
  value       = var.enable_api_integrations ? aws_api_gateway_stage.main[0].invoke_url : null
}

output "vpc_link_id" {
  description = "API Gateway VPC Link V2 ID"
  value       = aws_apigatewayv2_vpc_link.main.id
}

output "vpc_link_arn" {
  description = "API Gateway VPC Link V2 ARN"
  value       = aws_apigatewayv2_vpc_link.main.arn
}

output "jwt_authorizer_id" {
  description = "API Gateway JWT TOKEN authorizer ID"
  value       = aws_api_gateway_authorizer.jwt.id
}

