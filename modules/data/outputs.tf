output "storage_account_name" {
  value = azurerm_storage_account.datalake.name
}

output "storage_account_id" {
  value = azurerm_storage_account.datalake.id
}

output "datalake_endpoint" {
  value = azurerm_storage_account.datalake.primary_dfs_endpoint
}
