
# --------------------------------------------------
# NextGen Discover Customer Managed KMS Key
# --------------------------------------------------

resource "aws_kms_key" "main" {
  description              = var.description
  deletion_window_in_days  = var.deletion_window_in_days
  enable_key_rotation      = var.enable_key_rotation
  is_enabled               = true
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"

  tags = merge(var.tags, {
    Name      = "${var.project_name}-kms-key"
    Component = "KMS"
  })
}

# --------------------------------------------------
# KMS Key Alias
# --------------------------------------------------

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-key"
  target_key_id = aws_kms_key.main.key_id
}
