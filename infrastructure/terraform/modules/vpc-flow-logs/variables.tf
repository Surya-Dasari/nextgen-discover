variable "name" {
  description = "Name prefix for VPC Flow Logs resources"
  type        = string

  validation {
    condition     = length(trimspace(var.name)) > 0
    error_message = "The name must not be empty."
  }
}

variable "vpc_id" {
  description = "VPC ID for which Flow Logs will be enabled"
  type        = string

  validation {
    condition     = can(regex("^vpc-[0-9a-f]+$", var.vpc_id))
    error_message = "Provide a valid AWS VPC ID."
  }
}

variable "traffic_type" {
  description = "Traffic to capture: ALL, ACCEPT, or REJECT"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.traffic_type)
    error_message = "traffic_type must be ALL, ACCEPT, or REJECT."
  }
}

variable "log_retention_days" {
  description = "Number of days CloudWatch Logs retains Flow Logs"
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557,
      2922, 3288, 3653
    ], var.log_retention_days)

    error_message = "Choose a supported CloudWatch Logs retention period."
  }
}

variable "tags" {
  description = "Additional tags for Flow Logs resources"
  type        = map(string)
  default     = {}
}
