variable "project_name" {
  description = "Project name used for SNS and IAM resource naming"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster associated with Alertmanager"
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN allowed to use the Alertmanager role"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace running Alertmanager"
  type        = string
  default     = "observability"
}

variable "service_account" {
  description = "Kubernetes service account used by Alertmanager"
  type        = string
  default     = "kube-prometheus-stack-alertmanager"
}

variable "email_endpoint" {
  description = "Optional email recipient for SNS notifications"
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Tags applied to SNS and IAM resources"
  type        = map(string)
  default     = {}
}
