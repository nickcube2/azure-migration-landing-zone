variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "data_subnet_id" {
  type = string
}

variable "spoke_vnet_id" {
  type = string
}

variable "app_identity_principal_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
