variable "resource_group_name" {
  type        = string
  description = "Resource group for migration resources"
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

variable "migration_subnet_id" {
  type        = string
  description = "Subnet ID for DMS replication instance"
}

variable "tags" {
  type        = map(string)
  default     = {}
}