variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "sku_name" {
  description = "SKU name for Key Vault (standard or premium). Premium includes HSM-backed keys."
  type        = string
  default     = "standard"

  validation {
    condition     = can(regex("^(standard|premium)$", var.sku_name))
    error_message = "sku_name must be either 'standard' or 'premium'."
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = false
}

variable "network_acls_default_action" {
  description = "Default action for network ACLs (Allow or Deny). Deny is recommended for security."
  type        = string
  default     = "Deny"

  validation {
    condition     = can(regex("^(Allow|Deny)$", var.network_acls_default_action))
    error_message = "network_acls_default_action must be either 'Allow' or 'Deny'. 'Deny' is recommended for security."
  }
}

variable "network_acls_bypass" {
  description = "Network ACLs bypass setting (None or AzureServices). AzureServices allows trusted Microsoft services."
  type        = string
  default     = "AzureServices"

  validation {
    condition     = can(regex("^(None|AzureServices)$", var.network_acls_bypass))
    error_message = "network_acls_bypass must be either 'None' or 'AzureServices'."
  }
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "access_policies" {
  description = "List of access policies for the Key Vault"
  type = list(object({
    object_id               = string
    secret_permissions      = list(string)
    key_permissions         = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
  }))
  default = []
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for Key Vault"
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "create_private_dns_zone" {
  description = "Create a private DNS zone for Key Vault"
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

variable "secrets" {
  description = "Map of secrets to store in Key Vault (name => value). Secret names should use kebab-case (e.g., 'sql-connection-string')."
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    condition = alltrue([
      for name in keys(var.secrets) : can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", name))
    ])
    error_message = "Secret names must use kebab-case format (lowercase letters, numbers, and hyphens only, e.g., 'sql-connection-string')."
  }
}
