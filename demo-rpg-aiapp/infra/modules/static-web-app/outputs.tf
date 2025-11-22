output "static_web_app_id" {
  description = "ID of the Static Web App"
  value       = azurerm_static_web_app.swa.id
}

output "static_web_app_name" {
  description = "Name of the Static Web App"
  value       = azurerm_static_web_app.swa.name
}

output "default_host_name" {
  description = "Default hostname of the Static Web App"
  value       = azurerm_static_web_app.swa.default_host_name
}

output "api_key" {
  description = "API key for the Static Web App"
  value       = azurerm_static_web_app.swa.api_key
  sensitive   = true
}
