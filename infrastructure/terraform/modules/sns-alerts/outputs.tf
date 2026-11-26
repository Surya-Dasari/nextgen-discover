output "topic_arn" {
  description = "SNS topic ARN used by Alertmanager"
  value       = aws_sns_topic.alerts.arn
}

output "topic_name" {
  description = "SNS topic name"
  value       = aws_sns_topic.alerts.name
}

output "alertmanager_role_arn" {
  description = "IAM role ARN associated with Alertmanager"
  value       = aws_iam_role.alertmanager.arn
}

output "email_subscription_pending_confirmation" {
  description = "Whether the optional email subscription is awaiting confirmation"
  value = (
    length(aws_sns_topic_subscription.email) > 0
    ? aws_sns_topic_subscription.email[0].pending_confirmation
    : null
  )
}
