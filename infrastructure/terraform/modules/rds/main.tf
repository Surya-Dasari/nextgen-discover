resource "aws_db_subnet_group" "main" {
  name        = "${var.db_identifier}-subnet-group"
  description = "Private DB subnets for NextGen Discover PostgreSQL"

  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name      = "${var.db_identifier}-subnet-group"
    Component = "database"
  })
}

resource "aws_db_instance" "main" {
  identifier = var.db_identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.master_username

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.vpc_security_group_ids

  publicly_accessible = false
  multi_az            = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = "19:00-19:30"
  maintenance_window      = "sun:20:00-sun:20:30"

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  copy_tags_to_snapshot    = true
  deletion_protection      = var.deletion_protection
  skip_final_snapshot      = var.skip_final_snapshot
  delete_automated_backups = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  performance_insights_enabled = false
  monitoring_interval          = 0

  tags = merge(var.tags, {
    Name      = var.db_identifier
    Component = "database"
  })
}
