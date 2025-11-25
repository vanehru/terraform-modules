output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  value = { for k, s in azurerm_subnet.subnets : k => s.id }
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database_id" {
  value = azurerm_mssql_database.db.id
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "openai_account_id" {
  value = azurerm_cognitive_account.openai.id
}

output "openai_deployment_id" {
  value = azurerm_cognitive_deployment.openai_model.id
}

output "static_site_id" {
  value = azurerm_static_web_app.static.id
}
