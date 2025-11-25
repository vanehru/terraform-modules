output "function_app_id" {
  value       = azurerm_linux_function_app.function.id
  description = "ID of the Function App"
}

output "function_app_name" {
  value       = azurerm_linux_function_app.function.name
  description = "Name of the Function App"
}

output "function_app_default_hostname" {
  value       = azurerm_linux_function_app.function.default_hostname
  description = "Default hostname of the Function App"
}

output "function_app_identity_principal_id" {
  value       = azurerm_linux_function_app.function.identity[0].principal_id
  description = "Principal ID of the Function App managed identity"
}

output "service_plan_id" {
  value       = azurerm_service_plan.plan.id
  description = "ID of the App Service Plan"
}
