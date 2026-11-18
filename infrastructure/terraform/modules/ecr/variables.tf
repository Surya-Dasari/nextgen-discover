
variable "project_name" {
  description = "Project name used for ECR repository naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "repository_names" {
  description = "Application repository names to create in ECR"
  type        = set(string)

  validation {
    condition = (
      length(var.repository_names) > 0 &&
      alltrue([
        for name in var.repository_names :
        can(regex("^[a-z0-9]+([._-][a-z0-9]+)*$", name))
      ])
    )
    error_message = "Repository names must be valid lowercase ECR repository names."
  }
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image vulnerability scanning on image push"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for ECR repository encryption"
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Additional tags for ECR repositories"
  type        = map(string)
  default     = {}
}
