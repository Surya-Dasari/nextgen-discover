variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster associated with Loki"
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN allowed to use the Loki role"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace running Loki"
  type        = string
  default     = "observability"
}

variable "service_account" {
  description = "Kubernetes service account used by Loki"
  type        = string
  default     = "loki"
}

variable "tags" {
  description = "Tags applied to Loki storage resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region used for Loki storage"
  type        = string
}
