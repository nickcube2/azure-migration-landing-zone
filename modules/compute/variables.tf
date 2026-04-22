variable "resource_group_name" {
  type        = string
  description = "Resource group for compute resources"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "project" {
  type        = string
  description = "Project name for resource naming"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "aks_subnet_id" {
  type        = string
  description = "Subnet ID for AKS node pools — from networking module"
}

variable "app_identity_id" {
  type        = string
  description = "Managed identity ID — from identity module"
}

variable "app_identity_client_id" {
  type        = string
  description = "Managed identity client ID — for workload identity"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.33.8"
}

variable "system_node_count" {
  type        = number
  description = "Number of system nodes"
  default     = 1
}

variable "user_node_count" {
  type        = number
  description = "Number of user nodes for workloads"
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "VM size for nodes — Standard_D2as_v7 is cheapest for dev"
  default     = "Standard_D2as_v7"
}

variable "tags" {
  type        = map(string)
  default     = {}
}