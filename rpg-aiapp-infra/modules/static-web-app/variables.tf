variable "static_web_app_name" {
  description = "Name of the Static Web App"
  type        = string
}

variable "location" {
  description = "Azure region for the Static Web App"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_tier" {
  description = "SKU tier for Static Web App (Free or Standard)"
  type        = string
  default     = "Free"
}

variable "sku_size" {
  description = "SKU size for Static Web App"
  type        = string
  default     = "Free"
}

variable "function_app_id" {
  description = "ID of the Function App to link with Static Web App"
  type        = string
  default     = null
}

variable "custom_domain_name" {
  description = "Custom domain name for Static Web App"
  type        = string
  default     = null
}

variable "validation_type" {
  description = "Domain validation type (cname-delegation or dns-txt-token)"
  type        = string
  default     = "cname-delegation"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
