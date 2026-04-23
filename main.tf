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

module "identity" {
  source = "./modules/identity"

  resource_group_name = azurerm_resource_group.security.name
  location            = var.location
  project             = var.project
  environment         = var.environment
  tenant_id           = var.tenant_id
  spoke_vnet_id       = module.networking.spoke_vnet_id
  data_subnet_id      = module.networking.data_subnet_id
  tags                = var.tags

  depends_on = [module.networking]
}

module "compute" {
  source = "./modules/compute"

  resource_group_name    = azurerm_resource_group.workload.name
  location               = var.location
  project                = var.project
  environment            = var.environment
  aks_subnet_id          = module.networking.aks_subnet_id
  app_identity_id        = module.identity.app_identity_id
  app_identity_client_id = module.identity.app_identity_client_id
  kubernetes_version     = "1.33.8"
  system_node_count      = 1
  user_node_count        = 1
  node_vm_size           = "Standard_D2as_v7"
  tags                   = var.tags

  depends_on = [module.networking, module.identity]
}

module "data" {
  source = "./modules/data"

  resource_group_name       = azurerm_resource_group.data.name
  location                  = var.location
  project                   = var.project
  environment               = var.environment
  data_subnet_id            = module.networking.data_subnet_id
  spoke_vnet_id             = module.networking.spoke_vnet_id
  app_identity_principal_id = module.identity.app_identity_principal_id
  tags                      = var.tags

  depends_on = [module.networking, module.identity]
}

module "migration" {
  source = "./modules/migration"

  resource_group_name = azurerm_resource_group.migration.name
  location            = var.location
  project             = var.project
  environment         = var.environment
  migration_subnet_id = module.networking.migration_subnet_id
  tags                = var.tags

  depends_on = [module.networking]
}