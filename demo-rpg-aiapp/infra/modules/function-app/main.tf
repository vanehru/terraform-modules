# Storage Account for Function App
resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
  
  public_network_access_enabled = var.storage_public_network_access_enabled
  
  network_rules {
    default_action             = var.storage_network_default_action
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.storage_allowed_subnet_ids
  }

  tags = var.tags
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage_endpoint" {
  count               = var.enable_storage_private_endpoint ? 1 : 0
  name                = "${var.storage_account_name}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.storage_private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private DNS Zone for Storage Account
resource "azurerm_private_dns_zone" "storage_dns" {
  count               = var.enable_storage_private_endpoint && var.create_storage_private_dns_zone ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link Storage DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage_dns_link" {
  count                 = var.enable_storage_private_endpoint && var.create_storage_private_dns_zone ? 1 : 0
  name                  = "${var.storage_account_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns[0].name
  virtual_network_id    = var.storage_virtual_network_id

  tags = var.tags
}

# DNS A record for Storage Account's private endpoint
resource "azurerm_private_dns_a_record" "storage_dns_a_record" {
  count               = var.enable_storage_private_endpoint && var.create_storage_private_dns_zone ? 1 : 0
  name                = var.storage_account_name
  zone_name           = azurerm_private_dns_zone.storage_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.storage_endpoint[0].private_service_connection[0].private_ip_address]

  tags = var.tags
}

# App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = var.tags
}

# Managed Identity for the Function App
resource "azurerm_user_assigned_identity" "func_identity" {
  count               = var.create_managed_identity ? 1 : 0
  name                = "${var.function_app_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# Function App
resource "azurerm_linux_function_app" "function" {
  name                       = var.function_app_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  app_settings = merge(
    {
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
    },
    var.app_settings
  )

  dynamic "identity" {
    for_each = var.create_managed_identity ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.func_identity[0].id]
    }
  }

  site_config {
    vnet_route_all_enabled = var.vnet_route_all_enabled

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        python_version              = lookup(application_stack.value, "python_version", null)
        node_version                = lookup(application_stack.value, "node_version", null)
        dotnet_version              = lookup(application_stack.value, "dotnet_version", null)
        java_version                = lookup(application_stack.value, "java_version", null)
        powershell_core_version     = lookup(application_stack.value, "powershell_core_version", null)
      }
    }
  }

  tags = var.tags
}

# VNet Integration for Function App
resource "azurerm_app_service_virtual_network_swift_connection" "function_vnet_integration" {
  count          = var.enable_vnet_integration ? 1 : 0
  app_service_id = azurerm_linux_function_app.function.id
  subnet_id      = var.vnet_integration_subnet_id
}
