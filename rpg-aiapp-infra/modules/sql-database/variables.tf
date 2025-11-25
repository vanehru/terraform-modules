variable "sql_server_name" {
  description = "Name of the SQL Server"
  type        = string
}

variable "database_name" {
  description = "Name of the SQL Database"
  type        = string
}

variable "location" {
  description = "Azure region for the SQL Server"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sql_server_version" {
  description = "Version of SQL Server (e.g., 12.0)"
  type        = string
  default     = "12.0"
}

variable "admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Administrator password for SQL Server (must be at least 8 characters with complexity requirements)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "SQL Server password must be at least 8 characters long."
  }
}

variable "minimum_tls_version" {
  description = "Minimum TLS version for SQL Server"
  type        = string
  default     = "1.2"
}

variable "azuread_admin_login" {
  description = "Azure AD admin login name"
  type        = string
  default     = null
}

variable "azuread_admin_object_id" {
  description = "Azure AD admin object ID"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access to SQL Server (should be false for production with private endpoint)"
  type        = bool
  default     = false
  
  validation {
    condition     = var.public_network_access_enabled == false || var.enable_private_endpoint == false
    error_message = "For security, if private endpoint is enabled, public network access should be disabled."
  }
}

variable "collation" {
  description = "Database collation"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "sku_name" {
  description = "SKU name for the database (e.g., GP_S_Gen5_2, Basic, S0)"
  type        = string
  default     = "GP_S_Gen5_2"
}

variable "max_size_gb" {
  description = "Maximum size of the database in GB"
  type        = number
  default     = 32
}

variable "zone_redundant" {
  description = "Enable zone redundancy for the database"
  type        = bool
  default     = false
}

variable "allow_azure_services" {
  description = "Allow Azure services to access the SQL Server"
  type        = bool
  default     = true
}

variable "firewall_rules" {
  description = "Map of firewall rules (name => {start_ip, end_ip})"
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default = {}
}

variable "subnet_id" {
  description = "Subnet ID for VNet rule"
  type        = string
  default     = null
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for SQL Server (recommended for production)"
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "create_private_dns_zone" {
  description = "Create a private DNS zone for SQL Server"
  type        = bool
  default     = true
}

variable "virtual_network_id" {
  description = "Virtual network ID for DNS zone link"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
