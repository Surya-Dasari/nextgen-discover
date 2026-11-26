output "controller_role_arn" {
  description = "Karpenter controller IAM role ARN"
  value       = aws_iam_role.controller.arn
}

output "controller_role_name" {
  description = "Karpenter controller IAM role name"
  value       = aws_iam_role.controller.name
}

output "node_role_arn" {
  description = "Karpenter EC2 node IAM role ARN"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Karpenter EC2 node IAM role name"
  value       = aws_iam_role.node.name
}

output "interruption_queue_name" {
  description = "Karpenter interruption SQS queue name"
  value       = aws_sqs_queue.interruption.name
}

output "interruption_queue_arn" {
  description = "Karpenter interruption SQS queue ARN"
  value       = aws_sqs_queue.interruption.arn
}

output "interruption_queue_url" {
  description = "Karpenter interruption SQS queue URL"
  value       = aws_sqs_queue.interruption.url
}
