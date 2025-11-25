# Function App Deployment Package (Phase 2)
# Deploy separately after core infrastructure is ready

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

# Data sources to reference existing infrastructure
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

data "azurerm_cognitive_account" "openai" {
  name                = var.openai_account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_mssql_server" "sql" {
  name                = var.sql_server_name
  resource_group_name = var.resource_group_name
}

# Function App Module
module "function_app" {
  source = "../modules/function-app"

  function_app_name      = var.function_app_name
  resource_group_name    = data.azurerm_resource_group.rg.name
  location               = data.azurerm_resource_group.rg.location
  service_plan_name      = var.service_plan_name
  sku_name               = var.sku_name
  storage_account_name   = var.storage_account_name
  python_version         = var.python_version
  tags                   = var.tags

  app_settings = merge(
    var.app_settings,
    {
      "AZURE_KEYVAULT_ENDPOINT" = data.azurerm_key_vault.kv.vault_uri
      "OPENAI_ENDPOINT"         = data.azurerm_cognitive_account.openai.endpoint
      "SQL_SERVER_FQDN"         = data.azurerm_mssql_server.sql.fully_qualified_domain_name
    }
  )
}

# Role assignment for Function App to access Key Vault
resource "azurerm_role_assignment" "function_kv_secrets_user" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.function_app.function_app_identity_principal_id
}
