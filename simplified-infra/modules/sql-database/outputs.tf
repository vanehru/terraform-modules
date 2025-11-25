output "server_id" {
  value       = azurerm_mssql_server.sql.id
  description = "ID of the SQL Server"
}

output "server_fqdn" {
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
  description = "Fully qualified domain name of the SQL Server"
}

output "database_id" {
  value       = azurerm_mssql_database.db.id
  description = "ID of the SQL Database"
}

output "database_name" {
  value       = azurerm_mssql_database.db.name
  description = "Name of the SQL Database"
}
