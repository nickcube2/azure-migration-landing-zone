output "key_vault_id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "Key Vault URI — used by applications to retrieve secrets"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "app_identity_id" {
  description = "Managed identity resource ID — assigned to AKS workloads"
  value       = azurerm_user_assigned_identity.app.id
}

output "app_identity_client_id" {
  description = "Managed identity client ID — used in workload identity federation"
  value       = azurerm_user_assigned_identity.app.client_id
}

output "app_identity_principal_id" {
  description = "Managed identity principal ID — used in RBAC assignments"
  value       = azurerm_user_assigned_identity.app.principal_id
}