# Get current public IP address for Key Vault access during deployment
data "http" "current_ip" {
  url = "https://api.ipify.org?format=text"
}

resource "azurerm_resource_group" "rg" {
  name     = var.azurerm_resource_group_name
  location = var.azurerm_resource_group_location

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
  }
}

# VNet and subnets
resource "azurerm_virtual_network" "vnet" {
  name                = "demo-rpg-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
  }
}

# Subnet 1: App Subnet (for Function App VNet integration)
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_subnet_cidr]

  service_endpoints = ["Microsoft.Web", "Microsoft.KeyVault"]

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
  address_prefixes     = [var.storage_subnet_cidr]

  service_endpoints = ["Microsoft.Storage"]
}

# Subnet 3: Key Vault Subnet (Key Vault Private Endpoint)
resource "azurerm_subnet" "keyvault_subnet" {
  name                 = "keyvault-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.keyvault_subnet_cidr]
  service_endpoints    = ["Microsoft.KeyVault"]
}

# Subnet 4: Database Subnet (SQL Database Private Endpoint)
resource "azurerm_subnet" "database_subnet" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.database_subnet_cidr]

  service_endpoints = ["Microsoft.Sql"]
}

# Subnet 5: OpenAI Subnet (OpenAI Private Endpoint)
resource "azurerm_subnet" "openai_subnet" {
  name                 = "openai-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.openai_subnet_cidr]
}

# Subnet 6: Deployment Subnet (Cloud Shell Container Instance)
resource "azurerm_subnet" "deployment_subnet" {
  name                 = "deployment-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.deployment_subnet_cidr]
  service_endpoints    = ["Microsoft.Storage"]  # Required for Cloud Shell storage account

  delegation {
    name = "container-delegation"
    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

# Random string for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Random password for SQL Server
resource "random_password" "sql_admin_password" {
  length  = 16
  special = true
}

# Function App Module - Y1 Consumption with public access
module "function_app" {
  count  = var.enable_function_app ? 1 : 0
  source = "./modules/function-app"

  function_app_name                = "demo-rpg-python-${random_string.suffix.result}"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  storage_account_name             = "pythonstore${random_string.suffix.result}"
  storage_account_tier             = "Standard"
  storage_account_replication_type = "LRS"
  app_service_plan_name            = "demo-python-plan-${random_string.suffix.result}"
  app_service_plan_sku             = "Y1"
  python_version                   = "3.9"
  create_managed_identity          = true
  vnet_route_all_enabled           = false
  enable_vnet_integration          = false

  # Public access for storage (no private endpoints)
  storage_public_network_access_enabled = true
  storage_network_default_action        = "Allow"
  enable_storage_private_endpoint       = false

  app_settings = {
    "CUSTOM_SETTING"         = "value"
    "KEY_VAULT_URI"          = module.key_vault.key_vault_uri
    "SQL_CONNECTION_SECRET"  = "sql-connection-string"
    "OPENAI_ENDPOINT_SECRET" = "openai-endpoint"
    "OPENAI_KEY_SECRET"      = "openai-key"
  }

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
  }
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name              = "demo-rpgkv123"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  network_acls_default_action = "Deny"
  network_acls_bypass         = "AzureServices"
  allowed_subnet_ids          = [azurerm_subnet.app_subnet.id, azurerm_subnet.keyvault_subnet.id, azurerm_subnet.deployment_subnet.id]
  allowed_ip_addresses        = [data.http.current_ip.response_body]

  access_policies = concat([
    {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
    }
  ], var.enable_function_app ? [{
    object_id          = module.function_app[0].function_app_identity_principal_id
    secret_permissions = ["Get", "List"]
  }] : [])

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
    module.openai,
    azurerm_container_group.deployment_container
  ]

  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.keyvault_subnet.id
  create_private_dns_zone    = true
  virtual_network_id         = azurerm_virtual_network.vnet.id

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
  }
}

# SQL Database Module
module "sql_database" {
  source = "./modules/sql-database"

  sql_server_name               = "rpg-sql-${random_string.suffix.result}"
  database_name                 = "rpg-gaming-db"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  admin_username                = "sqladmin"
  admin_password                = random_password.sql_admin_password.result
  sql_server_version            = "12.0"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  sku_name                      = "Basic"
  max_size_gb                   = 2
  allow_azure_services          = false
  # subnet_id is not needed when using private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.database_subnet.id
  create_private_dns_zone    = true
  virtual_network_id         = azurerm_virtual_network.vnet.id

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
  }
}

# OpenAI Module
module "openai" {
  source = "./modules/openai"

  openai_account_name = "rpg-openai-${random_string.suffix.result}"
  location                      = "East US"
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = "S0"
  public_network_access_enabled = true  # Changed to true for testing - private endpoint has timing issues
  enable_private_endpoint       = false  # Disabled due to Azure resource graph timing issues
  private_endpoint_subnet_id    = azurerm_subnet.openai_subnet.id
  create_private_dns_zone       = false  # Not needed without private endpoint
  virtual_network_id            = azurerm_virtual_network.vnet.id

  # OpenAI model deployments commented out - all versions deprecated as of 11/14/2025
  # Testing infrastructure without OpenAI models
  deployments = {}

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
  }
}

# Static Web App Module
module "static_web_app" {
  source = "./modules/static-web-app"

  static_web_app_name = "rpg-gaming-web"
  location            = "East Asia"
  resource_group_name = azurerm_resource_group.rg.name
  sku_tier            = "Standard"
  sku_size            = "Standard"
  # function_app_id linkage removed to avoid count dependency issues
  # You can link the function app manually after deployment if needed

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
  }
}

# Storage Account for Cloud Shell (user files and persistence)
resource "azurerm_storage_account" "cloud_shell" {
  name                     = "cloudshell${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Allow public access for Cloud Shell - it needs internet connectivity
  # network_rules removed to allow default public access

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
    purpose       = "cloud-shell-storage"
  }
}

# File share for Cloud Shell persistence
resource "azurerm_storage_share" "cloud_shell" {
  name                 = "cloudshell"
  storage_account_name = azurerm_storage_account.cloud_shell.name
  quota                = 6 # 6 GB for Cloud Shell
}

# Container Instance for deployment from VNet
resource "azurerm_container_group" "deployment_container" {
  name                = "deployment-container"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Private"

  # Network configuration - deploy in VNet
  subnet_ids = [azurerm_subnet.deployment_subnet.id]

  # Identity for Azure authentication
  identity {
    type = "SystemAssigned"
  }

  container {
    name   = "deployment-tools"
    image  = "mcr.microsoft.com/azure-cli:latest"
    cpu    = "1.0"
    memory = "2.0"

    # Keep container running for deployment tasks
    commands = [
      "/bin/sh",
      "-c",
      "apk add --no-cache nodejs npm git curl && npm install -g @azure/static-web-apps-cli && while true; do sleep 3600; done"
    ]

    # Environment variables for deployment
    environment_variables = {
      "AZURE_SUBSCRIPTION_ID" = data.azurerm_client_config.current.subscription_id
      "RESOURCE_GROUP" = azurerm_resource_group.rg.name
    }
  }

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
    purpose       = "vnet-deployment"
  }
}

# Get Azure AD info for access policies
data "azurerm_client_config" "current" {}

