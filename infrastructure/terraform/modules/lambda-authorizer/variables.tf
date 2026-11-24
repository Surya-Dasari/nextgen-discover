variable "project_name" {
  description = "Project name used for Lambda resource naming"
  type        = string
}

variable "jwt_public_key_pem" {
  description = "RSA public key in PEM format used to verify JWT signatures"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("BEGIN PUBLIC KEY", var.jwt_public_key_pem))
    error_message = "JWT public key must be a PEM-encoded public key."
  }
}

variable "jwt_issuer" {
  description = "Expected JWT issuer claim"
  type        = string

  validation {
    condition     = length(trimspace(var.jwt_issuer)) > 0
    error_message = "JWT issuer cannot be empty."
  }
}

variable "jwt_audience" {
  description = "Expected JWT audience claim"
  type        = string

  validation {
    condition     = length(trimspace(var.jwt_audience)) > 0
    error_message = "JWT audience cannot be empty."
  }
}

variable "tags" {
  description = "Tags applied to Lambda resources"
  type        = map(string)
  default     = {}
}
