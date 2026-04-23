variable "resource_group_name" {
  type        = string
  description = "Resource group for identity and security resources"
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

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID — needed for Key Vault access policies"
}

variable "spoke_vnet_id" {
  type        = string
  description = "Spoke VNet ID — for Key Vault private endpoint"
}

variable "data_subnet_id" {
  type        = string
  description = "Data subnet ID — where private endpoint is placed"
}

variable "tags" {
  type    = map(string)
  default = {}
}