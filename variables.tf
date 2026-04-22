variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "location" {
  type        = string
  description = "Primary Azure region for all resources"
  default     = "eastus2"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project" {
  type        = string
  description = "Project name — used in all resource naming"
  default     = "kpmg-migration"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

variable "sql_admin_password" {
  type        = string
  description = "SQL Server admin password"
  sensitive   = true
}