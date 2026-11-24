
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.name
}

output "eks_node_role_arn" {
  description = "ARN of the EKS worker node IAM role"
  value       = aws_iam_role.eks_node.arn
}

output "eks_node_role_name" {
  description = "Name of the EKS worker node IAM role"
  value       = aws_iam_role.eks_node.name
}

output "api_gateway_cloudwatch_role_arn" {
  description = "ARN of the API Gateway CloudWatch logging role"
  value       = aws_iam_role.api_gateway_cloudwatch.arn
}
