variable "resource_group_name" {
  type        = string
  description = "Resource group for networking resources"
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

variable "hub_vnet_cidr" {
  type        = string
  description = "CIDR block for hub VNet"
  default     = "10.0.0.0/16"
}

variable "spoke_vnet_cidr" {
  type        = string
  description = "CIDR block for spoke VNet"
  default     = "10.1.0.0/16"
}

variable "tags" {
  type        = map(string)
  default     = {}
}