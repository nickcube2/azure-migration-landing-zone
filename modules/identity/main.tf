# ─────────────────────────────────────────────
# DATA SOURCES
# Read existing Azure AD data we need
# ─────────────────────────────────────────────

# Get current client config — tells us who is running Terraform
# We use this to grant Terraform itself access to Key Vault
data "azurerm_client_config" "current" {}

# ─────────────────────────────────────────────
# RANDOM SUFFIX
# Key Vault names must be globally unique across all Azure
# Adding random suffix prevents naming collisions
# ─────────────────────────────────────────────

resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ─────────────────────────────────────────────
# KEY VAULT
# Central secret store — all secrets live here
# Applications read secrets at runtime via managed identity
# No secrets in code, config files, or environment variables
# ─────────────────────────────────────────────

resource "azurerm_key_vault" "main" {
  name                = "kv-${var.project}-${var.environment}-${random_string.kv_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # Soft delete — deleted secrets recoverable for 7 days
  # Protects against accidental deletion
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # false for dev — true in prod

  # Disable public network access
  # Only accessible via private endpoint from within the VNet
  public_network_access_enabled = false

  # RBAC model — modern approach over access policies
  # Roles assigned at Key Vault or secret level
  enable_rbac_authorization = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# ─────────────────────────────────────────────
# PRIVATE ENDPOINT FOR KEY VAULT
# Makes Key Vault accessible only from within the VNet
# No traffic goes over the public internet
# AWS equivalent: VPC Interface Endpoint for Secrets Manager
# ─────────────────────────────────────────────

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-${var.project}-kv-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "psc-kv-${var.environment}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# ─────────────────────────────────────────────
# PRIVATE DNS ZONE FOR KEY VAULT
# Without this, DNS resolves Key Vault to public IP
# even though private endpoint exists
# This overrides DNS so private IP is returned instead
# ─────────────────────────────────────────────

resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link DNS zone to spoke VNet
# Resources in the VNet will resolve Key Vault to private IP
resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = "dns-link-kv-spoke"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = var.spoke_vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# DNS A record pointing Key Vault hostname to private endpoint IP
resource "azurerm_private_dns_a_record" "key_vault" {
  name                = azurerm_key_vault.main.name
  zone_name           = azurerm_private_dns_zone.key_vault.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.key_vault.private_service_connection[0].private_ip_address]
}

# ─────────────────────────────────────────────
# MANAGED IDENTITY
# AWS equivalent: IAM Instance Profile / IRSA
# Applications use this identity to authenticate to Azure services
# No username, no password, no API key — ever
# ─────────────────────────────────────────────

resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${var.project}-app-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# ─────────────────────────────────────────────
# RBAC ASSIGNMENTS
# Grant managed identity access to Key Vault secrets
# Key Vault Secrets User = read secrets only (least privilege)
# ─────────────────────────────────────────────

# App identity can read secrets from Key Vault
resource "azurerm_role_assignment" "app_kv_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# Terraform service principal can manage secrets
# Needed so Terraform can create/update secrets during apply
resource "azurerm_role_assignment" "terraform_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}