output "function_app_id" {
  value       = module.function_app.function_app_id
  description = "ID of the Function App"
}

output "function_app_name" {
  value       = module.function_app.function_app_name
  description = "Name of the Function App"
}

output "function_app_url" {
  value       = "https://${module.function_app.function_app_default_hostname}"
  description = "URL of the Function App"
}

output "function_app_identity_principal_id" {
  value       = module.function_app.function_app_identity_principal_id
  description = "Principal ID of Function App managed identity"
}
