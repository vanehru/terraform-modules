output "function_app_id" {
  description = "ID of the Function App"
  value       = azurerm_linux_function_app.function.id
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.function.name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.function.default_hostname
}

output "function_app_identity_principal_id" {
  description = "Principal ID of the Function App managed identity"
  value       = var.create_managed_identity ? azurerm_user_assigned_identity.func_identity[0].principal_id : null
}

output "function_app_identity_id" {
  description = "ID of the Function App managed identity"
  value       = var.create_managed_identity ? azurerm_user_assigned_identity.func_identity[0].id : null
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.storage.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.storage.name
}

output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.plan.id
}

output "storage_private_endpoint_ip" {
  description = "Private IP address of the storage account private endpoint"
  value       = var.enable_storage_private_endpoint ? azurerm_private_endpoint.storage_endpoint[0].private_service_connection[0].private_ip_address : null
}
