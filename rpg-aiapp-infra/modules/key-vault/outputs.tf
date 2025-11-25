output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.kv.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "private_endpoint_id" {
  description = "ID of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.kv_endpoint[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.kv_endpoint[0].private_service_connection[0].private_ip_address : null
}

output "secret_ids" {
  description = "Map of secret names to their IDs"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_names" {
  description = "List of secret names stored in Key Vault"
  value       = keys(azurerm_key_vault_secret.secrets)
}

output "access_policy_count" {
  description = "Number of access policies configured"
  value       = length(var.access_policies)
}

output "network_acls_default_action" {
  description = "Default action for network ACLs"
  value       = var.network_acls_default_action
}
