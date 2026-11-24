
variable "name" {
  description = "Name prefix for security group resources"
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "The security group name must not be empty."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "Provide a valid AWS VPC ID."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC"
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "IPv4 CIDR ranges allowed to access the private ALB"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.alb_ingress_cidrs :
      can(cidrnetmask(cidr))
    ])
    error_message = "All provided values must be valid IPv4 CIDR blocks."
  }
}

variable "tags" {
  description = "Additional tags applied to security groups"
  type        = map(string)
  default     = {}
}
