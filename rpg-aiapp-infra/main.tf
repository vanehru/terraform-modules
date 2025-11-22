provider "azurerm" {
  features = {}
}

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

resource "azurerm_subnet" "function_subnet" {
  name                 = "function-app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Web"] # Needed for VNet integration
}

resource "azurerm_subnet" "endpoint_subnet" {
  name                 = "endpoint-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  enforce_private_link_endpoint_network_policies = true # Required for private endpoints
}

# Storage Account for Function App
resource "azurerm_storage_account" "storage" {
  name                     = "examplestoracc123"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# App Service Plan
resource "azurerm_app_service_plan" "plan" {
  name                = "example-appserviceplan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
}

# Managed Identity for the Function App
resource "azurerm_user_assigned_identity" "func_identity" {
  name                = "function-identity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Function App
resource "azurerm_linux_function_app" "function" {
  name                = "example-func"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_app_service_plan.plan.id
  storage_account_name = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.func_identity.id]
  }

  site_config {
    vnet_route_all_enabled = true
  }
}

# VNet Integration for Function App (delegated subnet)
resource "azurerm_app_service_virtual_network_swift_connection" "function_vnet_integration" {
  app_service_id = azurerm_linux_function_app.function.id
  subnet_id      = azurerm_subnet.function_subnet.id
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "examplekv123"
  location                    = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled     = false
  soft_delete_enabled          = true
  network_acls {
    default_action             = "Deny"
    bypass                    = "AzureServices"
    virtual_network_subnet_ids = [azurerm_subnet.endpoint_subnet.id, azurerm_subnet.function_subnet.id]
  }
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.func_identity.principal_id
    # Permissions as needed
    secret_permissions = ["get", "list"]
  }
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "kv_endpoint" {
  name                = "example-kv-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.endpoint_subnet.id

  private_service_connection {
    name                           = "example-keyvault-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "kv_dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link DNS zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_link" {
  name                  = "example-dns-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# DNS A record for Key Vault's private endpoint
resource "azurerm_private_dns_a_record" "kv_dns_a_record" {
  name                = azurerm_key_vault.kv.name
  zone_name           = azurerm_private_dns_zone.kv_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.kv_endpoint.private_service_connection[0].private_ip_address]
}

# Get Azure AD info for access policies
data "azurerm_client_config" "current" {}