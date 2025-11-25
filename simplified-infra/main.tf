# Phase 1: Resource Group, Network, Core Services (no private endpoints)

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefix]
}

# SQL Server & Database (Basic SKU)
resource "azurerm_mssql_server" "sql" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  tags                         = var.tags
}

resource "azurerm_mssql_database" "db" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.sql.id
  sku_name       = "Basic"
  max_size_gb    = 2
  zone_redundant = false
  tags           = var.tags
}

# Key Vault (public for now; restrict later in Phase 2)
resource "azurerm_key_vault" "kv" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  rbac_authorization_enabled = true
  tags                       = var.tags
}

data "azurerm_client_config" "current" {}

# Azure OpenAI Account (no network ACLs / endpoints yet)
resource "azurerm_cognitive_account" "openai" {
  name                = var.openai_account_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = "S0"
  tags                = var.tags
  public_network_access_enabled = true
}

resource "azurerm_cognitive_deployment" "openai_model" {
  name                 = var.openai_deployment_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.openai_model_name
    version = var.openai_model_version
  }

  sku {
    name     = var.openai_scale_type
    capacity = var.openai_capacity
  }

  version_upgrade_option = "OnceNewDefaultVersionAvailable"
}

# Static Web App (Free) - must use supported region
resource "azurerm_static_web_app" "static" {
  name                = var.static_site_name
  location            = "eastasia"  # japaneast not supported; using closest region
  resource_group_name = azurerm_resource_group.rg.name
  sku_size            = "Free"
  tags                = var.tags
}

# Outputs consolidated in outputs.tf
