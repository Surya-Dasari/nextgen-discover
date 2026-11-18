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
