variable "name" {
  description = "Name prefix for VPC resources"
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "The VPC name must not be empty."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zone_ids" {
  description = "AWS Availability Zone IDs used by the VPC"
  type        = list(string)

  validation {
    condition = (
      length(var.availability_zone_ids) >= 2 &&
      length(distinct(var.availability_zone_ids)) == length(var.availability_zone_ids)
    )
    error_message = "Provide at least two unique Availability Zone IDs."
  }
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.public_subnet_cidrs) == length(var.availability_zone_ids) &&
      alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Provide one valid IPv4 public subnet CIDR per Availability Zone."
  }
}

variable "private_app_subnet_cidrs" {
  description = "IPv4 CIDR blocks for private application subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.private_app_subnet_cidrs) == length(var.availability_zone_ids) &&
      alltrue([for cidr in var.private_app_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Provide one valid IPv4 application subnet CIDR per Availability Zone."
  }
}

variable "private_db_subnet_cidrs" {
  description = "IPv4 CIDR blocks for isolated database subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.private_db_subnet_cidrs) == length(var.availability_zone_ids) &&
      alltrue([for cidr in var.private_db_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Provide one valid IPv4 database subnet CIDR per Availability Zone."
  }
}

variable "eks_control_plane_subnet_cidrs" {
  description = "IPv4 CIDR blocks for EKS control-plane subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.eks_control_plane_subnet_cidrs) == length(var.availability_zone_ids) &&
      alltrue([for cidr in var.eks_control_plane_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Provide one valid IPv4 control-plane subnet CIDR per Availability Zone."
  }
}

variable "tags" {
  description = "Additional tags applied to VPC resources"
  type        = map(string)
  default     = {}
}
