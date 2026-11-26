
variable "project_name" {
  description = "Project name used for EKS resource naming"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.37"
}

variable "cluster_role_arn" {
  description = "IAM role ARN used by the EKS control plane"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN used by EKS worker nodes"
  type        = string
}

variable "cluster_subnet_ids" {
  description = "Dedicated subnets for EKS control-plane network interfaces"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Private application subnets for EKS worker nodes"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Enable public Kubernetes API endpoint access"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private Kubernetes API endpoint access"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to access the public Kubernetes API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type for EKS worker nodes"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "Node capacity type must be ON_DEMAND or SPOT."
  }
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Worker node root volume size in GiB"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags for EKS resources"
  type        = map(string)
  default     = {}
}

variable "worker_security_group_id" {
  description = "Custom security group attached to EKS worker nodes"
  type        = string
}

variable "cluster_admin_principal_arns" {
  description = "IAM principals granted EKS cluster administrator access"
  type        = set(string)
  default     = []
}

# --------------------------------------------------
# EKS Observability Node Group Variables
# --------------------------------------------------

variable "observability_node_instance_types" {
  description = "EC2 instance types for the dedicated observability node group"
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "observability_node_desired_size" {
  description = "Desired number of observability worker nodes"
  type        = number
  default     = 2
}

variable "observability_node_min_size" {
  description = "Minimum number of observability worker nodes"
  type        = number
  default     = 1
}

variable "observability_node_max_size" {
  description = "Maximum number of observability worker nodes"
  type        = number
  default     = 2
}

variable "observability_node_disk_size" {
  description = "Observability worker root volume size in GiB"
  type        = number
  default     = 30
}
