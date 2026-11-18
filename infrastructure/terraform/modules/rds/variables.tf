variable "db_identifier" {
  description = "RDS database instance identifier"
  type        = string
}

variable "db_name" {
  description = "Initial PostgreSQL database name"
  type        = string
  default     = "nextgendiscover"
}

variable "master_username" {
  description = "RDS master username"
  type        = string
  default     = "dbadmin"
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "instance_class" {
  description = "RDS DB instance class"
  type        = string
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "gp3"
}

variable "subnet_ids" {
  description = "Private DB subnet IDs"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Existing RDS security group IDs"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for RDS storage and managed credentials"
  type        = string
}

variable "backup_retention_period" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Protect the DB instance from deletion"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying the instance"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to RDS resources"
  type        = map(string)
  default     = {}
}
