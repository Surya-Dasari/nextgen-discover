
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "private_subnet_ids" {
  description = "Private application subnet IDs for API Gateway VPC Link"
  type        = list(string)
}

variable "vpc_link_security_group_id" {
  description = "Security group ID for API Gateway VPC Link"
  type        = string
}

variable "lambda_authorizer_function_arn" {
  description = "Lambda function ARN used by API Gateway authorizer"
  type        = string
}

variable "lambda_authorizer_invoke_arn" {
  description = "Lambda invocation ARN used by API Gateway authorizer"
  type        = string
}

variable "enable_api_integrations" {
  description = "Enable API Gateway private ALB integrations after the internal ALB is available"
  type        = bool
  default     = false
}

variable "api_alb_arn" {
  description = "Internal ALB ARN for API Gateway private integration"
  type        = string
  default     = null
  nullable    = true
}

variable "api_alb_dns_name" {
  description = "Internal ALB DNS name used as integration Host header"
  type        = string
  default     = null
  nullable    = true
}

