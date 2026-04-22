output "hub_vnet_id" {
  description = "Hub VNet ID — referenced by other modules"
  value       = azurerm_virtual_network.hub.id
}

output "spoke_vnet_id" {
  description = "Spoke VNet ID"
  value       = azurerm_virtual_network.spoke.id
}

output "aks_subnet_id" {
  description = "AKS subnet ID — passed to AKS module"
  value       = azurerm_subnet.aks.id
}

output "data_subnet_id" {
  description = "Data subnet ID — passed to private endpoints"
  value       = azurerm_subnet.data.id
}

output "migration_subnet_id" {
  description = "Migration subnet ID — passed to DMS module"
  value       = azurerm_subnet.migration.id
}