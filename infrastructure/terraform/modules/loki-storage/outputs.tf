output "bucket_name" {
  description = "S3 bucket used by Loki"
  value       = aws_s3_bucket.loki.bucket
}

output "bucket_arn" {
  description = "ARN of the Loki S3 bucket"
  value       = aws_s3_bucket.loki.arn
}

output "role_arn" {
  description = "IAM role ARN associated with Loki"
  value       = aws_iam_role.loki.arn
}
