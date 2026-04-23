# ─────────────────────────────────────────────
# RANDOM SUFFIX
# ─────────────────────────────────────────────

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ─────────────────────────────────────────────
# ADLS GEN2 — AZURE DATA LAKE STORAGE
# Hierarchical namespace enabled for Databricks
# Medallion containers (bronze/silver/gold)
# provisioned via CLI due to free tier network
# restrictions — see README for pattern
# ─────────────────────────────────────────────

resource "azurerm_storage_account" "datalake" {
  name                            = "st${var.project}${var.environment}${random_string.storage_suffix.result}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  is_hns_enabled                  = true
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

resource "azurerm_role_assignment" "app_storage" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.app_identity_principal_id
}

# ─────────────────────────────────────────────
# PRIVATE ENDPOINT FOR ADLS
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
