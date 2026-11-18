output "db_instance_id" {
  description = "RDS DB instance identifier"
  value       = aws_db_instance.main.id
}

output "db_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "RDS PostgreSQL hostname"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "PostgreSQL port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Initial database name"
  value       = aws_db_instance.main.db_name
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN containing the RDS master credentials"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "db_subnet_group_name" {
  description = "RDS subnet group name"
  value       = aws_db_subnet_group.main.name
}
