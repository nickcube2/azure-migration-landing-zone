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