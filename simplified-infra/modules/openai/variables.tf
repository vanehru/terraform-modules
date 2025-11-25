variable "account_name" {
  type        = string
  description = "Name of the OpenAI account"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "sku_name" {
  type        = string
  description = "SKU name for OpenAI"
  default     = "S0"
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access"
  default     = true
}

variable "deployment_name" {
  type        = string
  description = "Name of the model deployment"
}

variable "model_name" {
  type        = string
  description = "Name of the model"
  default     = "gpt-4o"
}

variable "model_version" {
  type        = string
  description = "Version of the model"
  default     = "2024-11-20"
}

variable "scale_type" {
  type        = string
  description = "Scale type for deployment"
  default     = "GlobalStandard"
}

variable "capacity" {
  type        = number
  description = "Capacity units for deployment"
  default     = 1
}

variable "version_upgrade_option" {
  type        = string
  description = "Version upgrade option"
  default     = "OnceNewDefaultVersionAvailable"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
