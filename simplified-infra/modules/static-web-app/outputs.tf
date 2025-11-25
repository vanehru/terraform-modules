output "id" {
  value       = azurerm_static_web_app.app.id
  description = "ID of the Static Web App"
}

output "default_host_name" {
  value       = azurerm_static_web_app.app.default_host_name
  description = "Default hostname of the Static Web App"
}

output "api_key" {
  value       = azurerm_static_web_app.app.api_key
  description = "API key for deployment"
  sensitive   = true
}
