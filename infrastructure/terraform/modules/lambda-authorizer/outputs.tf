output "lambda_function_arn" {
  description = "JWT authorizer Lambda function ARN"
  value       = aws_lambda_function.authorizer.arn
}

output "lambda_function_name" {
  description = "JWT authorizer Lambda function name"
  value       = aws_lambda_function.authorizer.function_name
}

output "lambda_invoke_arn" {
  description = "Lambda invocation ARN for API Gateway"
  value       = aws_lambda_function.authorizer.invoke_arn
}

output "lambda_execution_role_arn" {
  description = "Lambda execution IAM role ARN"
  value       = aws_iam_role.lambda_authorizer.arn
}
