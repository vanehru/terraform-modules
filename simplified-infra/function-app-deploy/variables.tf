variable "resource_group_name" {
  type        = string
  description = "Name of the existing resource group"
}

variable "key_vault_name" {
  type        = string
  description = "Name of the existing Key Vault"
}

variable "openai_account_name" {
  type        = string
  description = "Name of the existing OpenAI account"
}

variable "sql_server_name" {
  type        = string
  description = "Name of the existing SQL Server"
}

variable "function_app_name" {
  type        = string
  description = "Name for the Function App"
}

variable "service_plan_name" {
  type        = string
  description = "Name for the App Service Plan"
}

variable "sku_name" {
  type        = string
  description = "SKU for App Service Plan (B1, Y1, etc.)"
  default     = "B1"
}

variable "storage_account_name" {
  type        = string
  description = "Name for Function App storage account (must be unique, 3-24 chars, lowercase)"
}

variable "python_version" {
  type        = string
  description = "Python version"
  default     = "3.11"
}

variable "app_settings" {
  type        = map(string)
  description = "Additional app settings"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
