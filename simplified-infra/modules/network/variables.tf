variable "vnet_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
}

variable "subnets" {
  description = "Map of subnet configurations"
  type = map(object({
    address_prefix = string
  }))
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
