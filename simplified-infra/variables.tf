variable "location" {
  type        = string
  description = "Azure region for all resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}

variable "vnet_name" {
  type        = string
  description = "Virtual network name"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
}

variable "subnets" {
  description = "Map of subnet name => prefix"
  type = map(object({
    address_prefix = string
  }))
}

# SQL
variable "sql_server_name" {
  type        = string
  description = "Name for the Azure SQL Server"
}

variable "sql_admin_login" {
  type        = string
  description = "Admin login for SQL Server"
}

variable "sql_admin_password" {
  type        = string
  description = "Admin password for SQL Server"
  sensitive   = true
}

variable "sql_database_name" {
  type        = string
  description = "Primary database name"
}

# Key Vault
variable "key_vault_name" {
  type        = string
  description = "Key Vault name"
}

# OpenAI
variable "openai_account_name" {
  type        = string
  description = "Azure OpenAI cognitive account name"
}

variable "openai_model_name" {
  type        = string
  description = "Model name for deployment"
  default     = "gpt-4o"
}

variable "openai_model_version" {
  type        = string
  description = "Model version for deployment"
  default     = "2024-11-20"
}

variable "openai_deployment_name" {
  type        = string
  description = "Deployment name for the model"
  default     = "gpt4o"
}

variable "openai_scale_type" {
  type        = string
  description = "Scale type for deployment"
  default     = "GlobalStandard"
}

variable "openai_capacity" {
  type        = number
  description = "Capacity units for deployment"
  default     = 1
}

# Static Web App
variable "static_site_name" {
  type        = string
  description = "Static Web App name"
}
