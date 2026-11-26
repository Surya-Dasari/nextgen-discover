output "api_gateway_id" {
  value = module.api_gateway_waf.rest_api_id
}

output "api_gateway_invoke_url" {
  value = module.api_gateway_waf.invoke_url
}

output "api_gateway_waf_arn" {
  value = module.api_gateway_waf.web_acl_arn
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "api_gateway_vpc_link_id" {
  description = "API Gateway VPC Link ID"
  value       = module.api_gateway_waf.vpc_link_id
}

output "api_gateway_vpc_link_arn" {
  description = "API Gateway VPC Link ARN"
  value       = module.api_gateway_waf.vpc_link_arn
}

# --------------------------------------------------
# Loki S3 Storage
# --------------------------------------------------

output "loki_bucket_name" {
  description = "S3 bucket name used by Loki log storage"
  value       = module.loki_storage.bucket_name
}
