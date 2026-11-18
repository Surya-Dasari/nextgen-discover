variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "private_subnet_ids" {
  description = "Private application subnet IDs for API Gateway VPC Link"
  type        = list(string)
}

variable "vpc_link_security_group_id" {
  description = "Security group ID for API Gateway VPC Link"
  type        = string
}
