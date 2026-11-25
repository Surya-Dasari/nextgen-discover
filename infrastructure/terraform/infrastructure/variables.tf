variable "aws_region" {
  description = "AWS region for NextGen Discover infrastructure"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "nextgen-discover"
}

variable "enable_api_integrations" {
  description = "Enable API Gateway integrations after the internal ALB is available"
  type        = bool
  default     = false

  validation {
    condition = (
      !var.enable_api_integrations ||
      (
        var.api_alb_arn != null &&
        trimspace(var.api_alb_arn) != "" &&
        var.api_alb_dns_name != null &&
        trimspace(var.api_alb_dns_name) != ""
      )
    )
    error_message = "When API integrations are enabled, both ALB ARN and DNS name must be provided."
  }
}



variable "jwt_issuer" {
  description = "Expected issuer claim in access tokens"
  type        = string
  default     = "nextgen-discover-auth"
}

variable "jwt_audience" {
  description = "Expected audience claim in access tokens"
  type        = string
  default     = "nextgen-discover-api"
}



variable "api_alb_arn" {
  description = "Internal ALB ARN for API Gateway private integration"
  type        = string
  default     = null
  nullable    = true
}

variable "api_alb_dns_name" {
  description = "Internal ALB DNS name used as integration Host header"
  type        = string
  default     = null
  nullable    = true
}


# --------------------------------------------------
# GitHub Actions OIDC Identity
# --------------------------------------------------

variable "github_owner" {
  description = "GitHub account or organization name"
  type        = string
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub owner ID"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name without the owner"
  type        = string
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID"
  type        = string
}

variable "github_branch" {
  description = "Git branch allowed to assume the GitHub Actions IAM role"
  type        = string
}
