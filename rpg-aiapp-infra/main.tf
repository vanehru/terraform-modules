resource "azurerm_resource_group" "rg" {
  name     = "example-rg"
  location = "East US"
}

# VNet and subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet 1: Application Subnet (Static Web App + Function App)
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Web"]
  
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

# Subnet 2: Storage Subnet (Storage Account Private Endpoint)
resource "azurerm_subnet" "storage_subnet" {
  name                 = "storage-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
  service_endpoints = ["Microsoft.Storage"]
}

# Subnet 3: Key Vault Subnet (Key Vault Private Endpoint)
resource "azurerm_subnet" "keyvault_subnet" {
  name                 = "keyvault-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Subnet 4: Database Subnet (SQL Database Private Endpoint)
resource "azurerm_subnet" "database_subnet" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/24"]
  
  service_endpoints = ["Microsoft.Sql"]
}

# Subnet 5: OpenAI Subnet (OpenAI Private Endpoint)
resource "azurerm_subnet" "openai_subnet" {
  name                 = "openai-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.5.0/24"]
}

# Random password for SQL Server
resource "random_password" "sql_admin_password" {
  length  = 16
  special = true
}

# Function App Module
module "function_app" {
  source = "./modules/function-app"

  function_app_name              = "example-func"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  storage_account_name           = "examplestoracc123"
  storage_account_tier           = "Standard"
  storage_account_replication_type = "LRS"
  app_service_plan_name          = "example-appserviceplan"
  app_service_plan_sku           = "P1v2"
  create_managed_identity        = true
  vnet_route_all_enabled         = true
  enable_vnet_integration        = true
  vnet_integration_subnet_id     = azurerm_subnet.app_subnet.id
  
  # Storage Account Private Endpoint
  storage_public_network_access_enabled = false
  storage_network_default_action        = "Deny"
  storage_allowed_subnet_ids            = [azurerm_subnet.app_subnet.id, azurerm_subnet.storage_subnet.id]
  enable_storage_private_endpoint       = true
  storage_private_endpoint_subnet_id    = azurerm_subnet.storage_subnet.id
  create_storage_private_dns_zone       = true
  storage_virtual_network_id            = azurerm_virtual_network.vnet.id

  app_settings = {
    "CUSTOM_SETTING"          = "value"
    "KEY_VAULT_URI"           = module.key_vault.key_vault_uri
    "SQL_CONNECTION_SECRET"   = "sql-connection-string"
    "OPENAI_ENDPOINT_SECRET"  = "openai-endpoint"
    "OPENAI_KEY_SECRET"       = "openai-key"
  }

  tags = {
    environment = "development"
  }
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name                = "examplekv123"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = false
  network_acls_default_action   = "Deny"
  network_acls_bypass           = "AzureServices"
  allowed_subnet_ids            = [azurerm_subnet.app_subnet.id, azurerm_subnet.keyvault_subnet.id]
  
  access_policies = [
    {
      object_id          = module.function_app.function_app_identity_principal_id
      secret_permissions = ["Get", "List"]
    },
    {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
    }
  ]

  # Store SQL and OpenAI secrets
  secrets = {
    "sql-connection-string" = module.sql_database.connection_string
    "sql-username"          = module.sql_database.admin_username
    "sql-server-fqdn"       = module.sql_database.sql_server_fqdn
    "sql-database-name"     = module.sql_database.sql_database_name
    "openai-endpoint"       = module.openai.openai_endpoint
    "openai-key"            = module.openai.openai_primary_key
  }

  depends_on = [
    module.sql_database,
    module.openai
  ]

  enable_private_endpoint      = true
  private_endpoint_subnet_id   = azurerm_subnet.keyvault_subnet.id
  create_private_dns_zone      = true
  virtual_network_id           = azurerm_virtual_network.vnet.id

  tags = {
    environment = "development"
  }
}

# SQL Database Module
module "sql_database" {
  source = "./modules/sql-database"

  sql_server_name                = "rpg-gaming-sql-server"
  database_name                  = "rpg-gaming-db"
  location                       = azurerm_resource_group.rg.location
  resource_group_name            = azurerm_resource_group.rg.name
  admin_username                 = "sqladmin"
  admin_password                 = random_password.sql_admin_password.result
  sql_server_version             = "12.0"
  minimum_tls_version            = "1.2"
  public_network_access_enabled  = false
  sku_name                       = "GP_S_Gen5_2"
  max_size_gb                    = 32
  allow_azure_services           = true
  subnet_id                      = azurerm_subnet.database_subnet.id
  enable_private_endpoint        = true
  private_endpoint_subnet_id     = azurerm_subnet.database_subnet.id
  create_private_dns_zone        = true
  virtual_network_id             = azurerm_virtual_network.vnet.id

  tags = {
    environment = "development"
  }
}

# OpenAI Module
module "openai" {
  source = "./modules/openai"

  openai_account_name           = "rpg-gaming-openai"
  location                      = "East US"
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = "S0"
  public_network_access_enabled = false
  enable_private_endpoint       = true
  private_endpoint_subnet_id    = azurerm_subnet.openai_subnet.id
  create_private_dns_zone       = true
  virtual_network_id            = azurerm_virtual_network.vnet.id

  # Deploy GPT-4 and GPT-3.5-turbo models for gaming app
  deployments = {
    "gpt-4" = {
      model_name    = "gpt-4"
      model_version = "0613"
      scale_type    = "Standard"
      capacity      = 10
    }
    "gpt-35-turbo" = {
      model_name    = "gpt-35-turbo"
      model_version = "0613"
      scale_type    = "Standard"
      capacity      = 20
    }
  }

  tags = {
    environment = "development"
  }
}

# Static Web App Module
module "static_web_app" {
  source = "./modules/static-web-app"

  static_web_app_name = "rpg-gaming-web"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_tier            = "Standard"
  sku_size            = "Standard"
  function_app_id     = module.function_app.function_app_id

  tags = {
    environment = "development"
  }
}

# Get Azure AD info for access policies
data "azurerm_client_config" "current" {}