variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "gitops-reference"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

variable "node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "SPOT"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 5
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "gitops_repo_url" {
  description = "Git repository Argo CD reconciles from"
  type        = string
  default     = "https://github.com/pratheek888/gitops-eks-reference.git"
}

variable "argocd_chart_version" {
  description = "argo-cd Helm chart version"
  type        = string
  default     = "7.6.12"
}

variable "environment" {
  description = "Tag value for the environment"
  type        = string
  default     = "reference"
}
