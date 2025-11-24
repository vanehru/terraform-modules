variable "azurerm_resource_group_location" {
  description = "The Azure region where the resource group is located"
  type        = string
  default     = "Japan East"
  
  validation {
    condition = contains([
      "Japan East", "Japan West", "East US", "East US 2", "West US 2", 
      "Central US", "North Europe", "West Europe", "Southeast Asia"
    ], var.azurerm_resource_group_location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "azurerm_resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rpg-aiapp-rg"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.azurerm_resource_group_name))
    error_message = "Resource group name must contain only alphanumeric characters, periods, underscores, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_owner" {
  description = "Project owner for resource tagging"
  type        = string
  default     = "ootsuka"
}

variable "author" {
  description = "Author for resource tagging"
  type        = string
  default     = "Nehru"
}

# Network Configuration Variables
variable "vnet_address_space" {
  description = "Address space for the Virtual Network (172.16.0.0/16 to avoid 10.x.x.x conflicts)"
  type        = list(string)
  default     = ["172.16.0.0/16"]
  
  validation {
    condition = alltrue([
      for cidr in var.vnet_address_space : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "app_subnet_cidr" {
  description = "CIDR block for Application subnet (Function App VNet Integration)"
  type        = string
  default     = "172.16.1.0/24"
}

variable "storage_subnet_cidr" {
  description = "CIDR block for Storage subnet (Storage Account Private Endpoint)"
  type        = string
  default     = "172.16.2.0/24"
}

variable "keyvault_subnet_cidr" {
  description = "CIDR block for Key Vault subnet (Key Vault Private Endpoint)"
  type        = string
  default     = "172.16.3.0/24"
}

variable "database_subnet_cidr" {
  description = "CIDR block for Database subnet (SQL Database Private Endpoint)"
  type        = string
  default     = "172.16.4.0/24"
}

variable "openai_subnet_cidr" {
  description = "CIDR block for OpenAI subnet (Azure OpenAI Private Endpoint)"
  type        = string
  default     = "172.16.5.0/24"
}

variable "deployment_subnet_cidr" {
  description = "CIDR block for Deployment subnet (Cloud Shell Container Instance)"
  type        = string
  default     = "172.16.6.0/24"
}
