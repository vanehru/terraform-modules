variable "azurerm_resource_group_location" {
  description = "The Azure region where the resource group is located"
  type        = string
  default     = "Japan East"

}


variable "azurerm_resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rpg-aiapp-rg"

}

# Network Configuration Variables
variable "vnet_address_space" {
  description = "Address space for the Virtual Network (172.16.0.0/16 to avoid 10.x.x.x conflicts)"
  type        = list(string)
  default     = ["172.16.0.0/16"]
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
