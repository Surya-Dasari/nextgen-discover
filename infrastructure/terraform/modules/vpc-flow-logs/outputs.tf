output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.vpc.id
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.arn
}

output "iam_role_arn" {
  description = "IAM Role ARN used by VPC Flow Logs"
  value       = aws_iam_role.vpc_flow_logs.arn
}
