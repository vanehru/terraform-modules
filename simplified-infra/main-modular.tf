# Phase 1: Core Infrastructure with Modular Structure
# VNet → Subnets → Services (SQL, Key Vault, OpenAI, Static Web App)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "e7e33592-8507-4bfe-bf20-3e090f025329"
}

data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Network Module
module "network" {
  source = "./modules/network"

  vnet_name           = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
  subnets             = var.subnets
  tags                = var.tags

  depends_on = [azurerm_resource_group.rg]
}

# SQL Database Module
module "sql_database" {
  source = "./modules/sql-database"

  server_name                   = var.sql_server_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = var.location
  admin_login                   = var.sql_admin_login
  admin_password                = var.sql_admin_password
  database_name                 = var.sql_database_name
  sku_name                      = "Basic"
  max_size_gb                   = 2
  zone_redundant                = false
  public_network_access_enabled = true
  tags                          = var.tags

  depends_on = [azurerm_resource_group.rg]
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name                = var.key_vault_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
  tags                          = var.tags

  depends_on = [azurerm_resource_group.rg]
}

# OpenAI Module
module "openai" {
  source = "./modules/openai"

  account_name                  = var.openai_account_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = var.location
  sku_name                      = "S0"
  public_network_access_enabled = true
  deployment_name               = var.openai_deployment_name
  model_name                    = var.openai_model_name
  model_version                 = var.openai_model_version
  scale_type                    = var.openai_scale_type
  capacity                      = var.openai_capacity
  tags                          = var.tags

  depends_on = [azurerm_resource_group.rg]
}

# Static Web App Module
module "static_web_app" {
  source = "./modules/static-web-app"

  name                = var.static_site_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastasia" # Static Web Apps not available in japaneast
  sku_size            = "Free"
  sku_tier            = "Free"
  tags                = var.tags

  depends_on = [azurerm_resource_group.rg]
}
