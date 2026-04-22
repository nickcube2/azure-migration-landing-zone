# ─────────────────────────────────────────────
# RANDOM SUFFIX
# ─────────────────────────────────────────────

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ─────────────────────────────────────────────
# DATA SOURCES — current Terraform identity
# ─────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# ─────────────────────────────────────────────
# ADLS GEN2 — AZURE DATA LAKE STORAGE
# ─────────────────────────────────────────────

resource "azurerm_storage_account" "datalake" {
  name                     = "st${var.project}${var.environment}${random_string.storage_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true

  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"


  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = ["172.59.231.121"]  
  }

  tags = var.tags
}

# Grant Terraform identity Storage Blob Data Owner
# Required to create ADLS Gen2 filesystems
resource "azurerm_role_assignment" "terraform_storage_owner" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant app identity Storage Blob Data Contributor
resource "azurerm_role_assignment" "app_storage" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.app_identity_principal_id
}

# ─────────────────────────────────────────────
# ADLS CONTAINERS — MEDALLION ARCHITECTURE
# Depends on role assignment — must be owner first
# ─────────────────────────────────────────────

resource "time_sleep" "role_propagation" {
  depends_on      = [azurerm_role_assignment.terraform_storage_owner]
  create_duration = "60s"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "bronze" {
  name               = "bronze"
  storage_account_id = azurerm_storage_account.datalake.id
  depends_on         = [time_sleep.role_propagation]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "silver" {
  name               = "silver"
  storage_account_id = azurerm_storage_account.datalake.id
  depends_on         = [time_sleep.role_propagation]
}

resource "azurerm_storage_data_lake_gen2_filesystem" "gold" {
  name               = "gold"
  storage_account_id = azurerm_storage_account.datalake.id
  depends_on         = [time_sleep.role_propagation]
}

# ─────────────────────────────────────────────
# PRIVATE ENDPOINT FOR ADLS
# Must be in same region as VNet (eastus2)
# ─────────────────────────────────────────────

resource "azurerm_private_endpoint" "datalake" {
  name                = "pe-${var.project}-adls-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "psc-adls-${var.environment}"
    private_connection_resource_id = azurerm_storage_account.datalake.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "datalake" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "datalake" {
  name                  = "dns-link-adls-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.datalake.name
  virtual_network_id    = var.spoke_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_a_record" "datalake" {
  name                = azurerm_storage_account.datalake.name
  zone_name           = azurerm_private_dns_zone.datalake.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.datalake.private_service_connection[0].private_ip_address]
}

# ─────────────────────────────────────────────
# AZURE SQL — skip for now, free tier restricted
# We'll reference it in README as a pattern
# The private endpoint + DNS zone pattern is
# identical to what we did for ADLS above
# ─────────────────────────────────────────────