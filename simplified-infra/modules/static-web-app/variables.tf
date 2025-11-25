variable "name" {
  type        = string
  description = "Name of the Static Web App"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region (must be one of: westus2, centralus, eastus2, westeurope, eastasia)"
}

variable "sku_size" {
  type        = string
  description = "SKU size"
  default     = "Free"
}

variable "sku_tier" {
  type        = string
  description = "SKU tier"
  default     = "Free"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
