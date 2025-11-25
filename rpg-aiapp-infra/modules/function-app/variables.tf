variable "function_app_name" {
  description = "Name of the Function App"
  type        = string
}

variable "location" {
  description = "Azure region for the Function App"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account for Function App"
  type        = string
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "app_service_plan_sku" {
  description = "SKU for the App Service Plan (e.g., Y1 for Consumption, EP1 for Elastic Premium, P1v2 for Premium)"
  type        = string
  default     = "Y1"

  validation {
    condition     = can(regex("^(Y1|EP1|EP2|EP3|P1v2|P2v2|P3v2|S1|S2|S3)$", var.app_service_plan_sku))
    error_message = "SKU must be a valid App Service Plan SKU. Use Y1 for Consumption (no VNet integration), EP1-EP3 for Elastic Premium, or P1v2-P3v2 for Premium."
  }
}

variable "create_managed_identity" {
  description = "Create a user-assigned managed identity for the Function App"
  type        = bool
  default     = true
}

variable "app_settings" {
  description = "Additional app settings for the Function App"
  type        = map(string)
  default     = {}
}

variable "vnet_route_all_enabled" {
  description = "Route all traffic through VNet (only supported on Premium/Elastic Premium plans)"
  type        = bool
  default     = false
}

variable "enable_vnet_integration" {
  description = "Enable VNet integration for Function App (only supported on Premium/Elastic Premium plans, not on Consumption Y1)"
  type        = bool
  default     = false
}

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "application_stack" {
  description = "Application stack configuration for Function App"
  type = object({
    python_version          = optional(string)
    node_version            = optional(string)
    dotnet_version          = optional(string)
    java_version            = optional(string)
    powershell_core_version = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "storage_public_network_access_enabled" {
  description = "Enable public network access to storage account"
  type        = bool
  default     = false
}

variable "storage_network_default_action" {
  description = "Default action for storage account network rules"
  type        = string
  default     = "Deny"
}

variable "storage_allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access storage account"
  type        = list(string)
  default     = []
}

variable "enable_storage_private_endpoint" {
  description = "Enable private endpoint for storage account"
  type        = bool
  default     = false
}

variable "storage_private_endpoint_subnet_id" {
  description = "Subnet ID for storage account private endpoint"
  type        = string
  default     = null
}

variable "create_storage_private_dns_zone" {
  description = "Create private DNS zone for storage account"
  type        = bool
  default     = true
}

variable "storage_virtual_network_id" {
  description = "Virtual network ID for storage DNS zone link"
  type        = string
  default     = null
}
