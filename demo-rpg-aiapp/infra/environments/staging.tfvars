azurerm_resource_group_location = "Japan East"
azurerm_resource_group_name = "rg-rpgai-staging-001"
environment = "staging"
project_owner = "dev-team"
author = "Nehru"

vnet_address_space = ["172.16.0.0/16"]
app_subnet_cidr = "172.16.1.0/24"
storage_subnet_cidr = "172.16.2.0/24"
keyvault_subnet_cidr = "172.16.3.0/24"
database_subnet_cidr = "172.16.4.0/24"
openai_subnet_cidr = "172.16.5.0/24"
deployment_subnet_cidr = "172.16.6.0/24"