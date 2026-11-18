
variable "project_name" {
  description = "Project name used for KMS resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "description" {
  description = "Description of the customer-managed KMS key"
  type        = string
  default     = "NextGen Discover encryption key"
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled KMS key deletion"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic annual KMS key rotation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for KMS resources"
  type        = map(string)
  default     = {}
}
