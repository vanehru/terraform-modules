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
  description = "SKU name for Key Vault (standard or premium)"
  type        = string
  default     = "standard"
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = false
}

variable "network_acls_default_action" {
  description = "Default action for network ACLs (Allow or Deny)"
  type        = string
  default     = "Deny"
}

variable "network_acls_bypass" {
  description = "Network ACLs bypass setting"
  type        = string
  default     = "AzureServices"
}

variable "allowed_subnet_ids" {
  description = "List of subnet IDs allowed to access Key Vault"
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
  description = "Map of secrets to store in Key Vault (name => value)"
  type        = map(string)
  default     = {}
  sensitive   = true
}
