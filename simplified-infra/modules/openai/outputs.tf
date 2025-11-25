output "account_id" {
  value       = azurerm_cognitive_account.openai.id
  description = "ID of the OpenAI account"
}

output "account_endpoint" {
  value       = azurerm_cognitive_account.openai.endpoint
  description = "Endpoint of the OpenAI account"
}

output "deployment_id" {
  value       = azurerm_cognitive_deployment.deployment.id
  description = "ID of the model deployment"
}

output "primary_access_key" {
  value       = azurerm_cognitive_account.openai.primary_access_key
  description = "Primary access key for OpenAI account"
  sensitive   = true
}
