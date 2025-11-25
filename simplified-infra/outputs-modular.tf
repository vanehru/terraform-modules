output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the resource group"
}

output "resource_group_id" {
  value       = azurerm_resource_group.rg.id
  description = "ID of the resource group"
}

# Network Outputs
output "virtual_network_id" {
  value       = module.network.vnet_id
  description = "ID of the virtual network"
}

output "virtual_network_name" {
  value       = module.network.vnet_name
  description = "Name of the virtual network"
}

output "subnet_ids" {
  value       = module.network.subnet_ids
  description = "Map of subnet names to IDs"
}

# SQL Database Outputs
output "sql_server_id" {
  value       = module.sql_database.server_id
  description = "ID of the SQL Server"
}

output "sql_server_fqdn" {
  value       = module.sql_database.server_fqdn
  description = "Fully qualified domain name of the SQL Server"
}

output "sql_database_id" {
  value       = module.sql_database.database_id
  description = "ID of the SQL Database"
}

# Key Vault Outputs
output "key_vault_id" {
  value       = module.key_vault.key_vault_id
  description = "ID of the Key Vault"
}

output "key_vault_uri" {
  value       = module.key_vault.key_vault_uri
  description = "URI of the Key Vault"
}

output "key_vault_name" {
  value       = module.key_vault.key_vault_name
  description = "Name of the Key Vault"
}

# OpenAI Outputs
output "openai_account_id" {
  value       = module.openai.account_id
  description = "ID of the OpenAI account"
}

output "openai_account_endpoint" {
  value       = module.openai.account_endpoint
  description = "Endpoint of the OpenAI account"
}

output "openai_deployment_id" {
  value       = module.openai.deployment_id
  description = "ID of the OpenAI deployment"
}

# Static Web App Outputs
output "static_site_id" {
  value       = module.static_web_app.id
  description = "ID of the Static Web App"
}

output "static_site_url" {
  value       = module.static_web_app.default_host_name
  description = "Default hostname of the Static Web App"
}
