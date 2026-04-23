output "dms_id" {
  description = "Database Migration Service resource ID"
  value       = azurerm_database_migration_service.main.id
}

output "dms_name" {
  description = "DMS service name"
  value       = azurerm_database_migration_service.main.name
}

output "recovery_vault_id" {
  description = "Recovery Services Vault ID — used by ASR"
  value       = azurerm_recovery_services_vault.main.id
}

output "recovery_vault_name" {
  description = "Recovery Services Vault name"
  value       = azurerm_recovery_services_vault.main.name
}

output "migration_storage_name" {
  description = "Migration staging storage account name"
  value       = azurerm_storage_account.migration.name
}

output "migration_log_analytics_id" {
  description = "Log Analytics workspace ID for migration monitoring"
  value       = azurerm_log_analytics_workspace.migration.id
}