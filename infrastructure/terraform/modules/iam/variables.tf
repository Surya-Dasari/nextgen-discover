
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

variable "github_repository" {
  description = "GitHub repository allowed to assume the CI role"
  type        = string
  default     = "Surya-Dasari/nextgen-discover"
}

variable "github_branch" {
  description = "Git branch allowed to assume the CI role"
  type        = string
  default     = "dev"
}
