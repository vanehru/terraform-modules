azurerm_resource_group_location = "Japan East"
azurerm_resource_group_name     = "rpg-aiapp-staging-rg"
environment                     = "staging"
project_owner                   = "ootsuka"
author                          = "Nehru"

# Network Configuration
vnet_address_space      = ["172.16.0.0/24"]
app_subnet_cidr         = "172.16.0.0/27"
database_subnet_cidr    = "172.16.0.32/27"
storage_subnet_cidr     = "172.16.0.64/27"
keyvault_subnet_cidr    = "172.16.0.96/27"
openai_subnet_cidr      = "172.16.0.128/27"
deployment_subnet_cidr  = "172.16.0.160/27"
