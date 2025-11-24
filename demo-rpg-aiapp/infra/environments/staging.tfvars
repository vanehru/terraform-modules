azurerm_resource_group_location = "Japan East"
azurerm_resource_group_name     = "rpg-aiapp-staging-rg"
environment                     = "staging"
project_owner                   = "ootsuka"
author                          = "Nehru"

# Network Configuration
vnet_address_space      = ["10.0.0.0/16"]
app_subnet_cidr         = ["10.0.1.0/24"]
database_subnet_cidr    = ["10.0.2.0/24"]
storage_subnet_cidr     = ["10.0.3.0/24"]
keyvault_subnet_cidr    = ["10.0.4.0/24"]
openai_subnet_cidr      = ["10.0.5.0/24"]
deployment_subnet_cidr  = ["10.0.6.0/24"]
