variable "project_name" {
  description = "Project name used for Karpenter resource naming"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "tags" {
  description = "Tags applied to Karpenter resources"
  type        = map(string)
  default     = {}
}
