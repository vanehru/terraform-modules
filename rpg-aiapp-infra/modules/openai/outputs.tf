output "openai_account_id" {
  description = "ID of the OpenAI account"
  value       = azurerm_cognitive_account.openai.id
}

output "openai_account_name" {
  description = "Name of the OpenAI account"
  value       = azurerm_cognitive_account.openai.name
}

output "openai_endpoint" {
  description = "Endpoint URL of the OpenAI service"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_primary_key" {
  description = "Primary access key for OpenAI service"
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "openai_secondary_key" {
  description = "Secondary access key for OpenAI service"
  value       = azurerm_cognitive_account.openai.secondary_access_key
  sensitive   = true
}

output "deployment_ids" {
  description = "Map of deployment names to IDs"
  value       = { for k, v in azurerm_cognitive_deployment.deployment : k => v.id }
}

output "private_endpoint_ip" {
  description = "Private IP address of the private endpoint"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.openai_endpoint[0].private_service_connection[0].private_ip_address : null
}
