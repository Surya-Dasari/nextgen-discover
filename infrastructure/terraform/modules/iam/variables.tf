
variable "project_name" {
  description = "Project name used for IAM resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Additional tags for IAM resources"
  type        = map(string)
  default     = {}
}

# --------------------------------------------------
# GitHub Actions OIDC Configuration
# --------------------------------------------------

variable "ecr_repository_arns" {
  description = "ARNs of ECR repositories GitHub Actions can publish images to"
  type        = map(string)
}

variable "github_owner" {
  description = "GitHub account or organization name"
  type        = string
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub owner ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "GitHub owner ID must contain only digits."
  }
}

variable "github_repository" {
  description = "GitHub repository name without the owner"
  type        = string
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "GitHub repository ID must contain only digits."
  }
}

variable "github_branch" {
  description = "Git branch allowed to assume the CI role"
  type        = string
}
