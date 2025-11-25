output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID of the virtual network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the virtual network"
}

output "subnet_ids" {
  value       = { for k, s in azurerm_subnet.subnets : k => s.id }
  description = "Map of subnet names to IDs"
}
