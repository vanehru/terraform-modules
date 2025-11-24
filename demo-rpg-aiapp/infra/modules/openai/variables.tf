variable "openai_account_name" {
  description = "Name of the OpenAI account"
  type        = string
}

variable "location" {
  description = "Azure region for the OpenAI service"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sku_name" {
  description = "SKU name for OpenAI service (S0)"
  type        = string
  default     = "S0"
}

variable "custom_subdomain_name" {
  description = "Custom subdomain name for OpenAI service"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access to OpenAI service"
  type        = bool
  default     = false
}

variable "enable_network_acls" {
  description = "Enable network ACLs for OpenAI service"
  type        = bool
  default     = false
}

variable "network_acls_default_action" {
  description = "Default action for network ACLs (Allow or Deny)"
  type        = string
  default     = "Deny"
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_id" {
  description = "Subnet ID allowed to access OpenAI service"
  type        = string
  default     = null
}

variable "deployments" {
  description = "Map of OpenAI model deployments"
  type = map(object({
    model_name    = string
    model_version = string
    scale_type    = string
    capacity      = number
  }))
  default = {}
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for OpenAI service"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the private endpoint"
  type        = string
  default     = null
}

variable "create_private_dns_zone" {
  description = "Create a private DNS zone for OpenAI service"
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
