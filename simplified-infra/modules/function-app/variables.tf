variable "function_app_name" {
  type        = string
  description = "Name of the Function App"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "service_plan_name" {
  type        = string
  description = "Name of the App Service Plan"
}

variable "sku_name" {
  type        = string
  description = "SKU for App Service Plan (e.g., Y1 for consumption, B1 for basic)"
  default     = "B1"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account for Function App"
}

variable "python_version" {
  type        = string
  description = "Python version for Function App"
  default     = "3.11"
}

variable "app_settings" {
  type        = map(string)
  description = "Application settings for Function App"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
