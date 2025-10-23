variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "terraform-demo-resources"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central India"
  
  validation {
    condition = contains([
      "Central India",
      "South India",
      "West India",
      "East US",
      "West US 2",
      "North Europe",
      "West Europe"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-demo"
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
  
  validation {
    condition = contains([
      "LRS", 
      "GRS", 
      "RAGRS", 
      "ZRS", 
      "GZRS", 
      "RAGZRS"
    ], var.storage_replication_type)
    error_message = "Invalid replication type."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}