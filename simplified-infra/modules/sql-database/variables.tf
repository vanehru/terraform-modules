variable "server_name" {
  type        = string
  description = "Name of the SQL Server"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "admin_login" {
  type        = string
  description = "Administrator login name"
}

variable "admin_password" {
  type        = string
  description = "Administrator password"
  sensitive   = true
}

variable "database_name" {
  type        = string
  description = "Name of the database"
}

variable "sku_name" {
  type        = string
  description = "SKU name for the database"
  default     = "Basic"
}

variable "max_size_gb" {
  type        = number
  description = "Maximum size of the database in GB"
  default     = 2
}

variable "zone_redundant" {
  type        = bool
  description = "Enable zone redundancy"
  default     = false
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
