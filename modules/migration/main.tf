# ─────────────────────────────────────────────
# RANDOM SUFFIX
# ─────────────────────────────────────────────

resource "random_string" "migration_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ─────────────────────────────────────────────
# AZURE DATABASE MIGRATION SERVICE
# Migrates databases from on-prem to Azure
# Supports: SQL Server, MySQL, PostgreSQL, Oracle
# Two task types:
#   full-load: one-time bulk copy
#   full-load-and-cdc: bulk copy + continuous sync
# AWS equivalent: AWS Database Migration Service
# ─────────────────────────────────────────────

resource "azurerm_database_migration_service" "main" {
  name                = "dms-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Premium SKU required for CDC (continuous replication)
  # GeneralPurpose_4vCores = 4 vCPUs
  # Size up for larger databases or higher throughput
  # AWS equivalent: dms.r5.large replication instance
  sku_name = "Premium_4vCores"

  # DMS runs inside the VNet
  # Can reach on-prem via VPN/ExpressRoute
  # Can reach Azure SQL via private endpoint
  subnet_id = var.migration_subnet_id

  tags = var.tags
}

# ─────────────────────────────────────────────
# RECOVERY SERVICES VAULT
# Used by Azure Site Recovery (ASR)
# ASR replicates on-prem VMs to Azure continuously
# On failover/migration: VM launches in Azure
# AWS equivalent: AWS Application Migration Service (MGN)
# ─────────────────────────────────────────────

resource "azurerm_recovery_services_vault" "main" {
  name                = "rsv-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Standard SKU — supports ASR and backup
  sku = "Standard"

  # Soft delete — deleted backups retained 14 days
  # Protects against accidental deletion
  soft_delete_enabled = true

  # Immutability — prevents backup tampering
  # Critical for compliance in regulated industries
  immutability = "Disabled"  # Enable in prod

  tags = var.tags
}

# ─────────────────────────────────────────────
# MIGRATION STAGING STORAGE
# Temporary storage during migration
# DMS stages data here during bulk load
# ASR stores replication data here
# AWS equivalent: S3 bucket used by DMS/MGN
# ─────────────────────────────────────────────

resource "azurerm_storage_account" "migration" {
  name                     = "stmig${var.project}${var.environment}${random_string.migration_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Public access enabled for migration staging
  # DMS and ASR need to write here from their managed services
  # Lock down after migration completes
  public_network_access_enabled = true
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"

  tags = var.tags
}

# ─────────────────────────────────────────────
# MIGRATION LOG ANALYTICS
# Tracks DMS task progress and errors
# ASR replication health and alerts
# ─────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "migration" {
  name                = "law-${var.project}-migration-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}