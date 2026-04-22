# ─────────────────────────────────────────────
# RESOURCE GROUPS
# Container for all resources in this landing zone
# On a real engagement: one RG per workload layer
# ─────────────────────────────────────────────

resource "azurerm_resource_group" "hub" {
  name     = "rg-${var.project}-hub-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "workload" {
  name     = "rg-${var.project}-workload-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "data" {
  name     = "rg-${var.project}-data-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "security" {
  name     = "rg-${var.project}-security-${var.environment}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "migration" {
  name     = "rg-${var.project}-migration-${var.environment}"
  location = var.location
  tags     = var.tags
}

module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.hub.name
  location            = var.location
  project             = var.project
  environment         = var.environment
  hub_vnet_cidr       = "10.0.0.0/16"
  spoke_vnet_cidr     = "10.1.0.0/16"
  tags                = var.tags

  depends_on = [azurerm_resource_group.hub]
}