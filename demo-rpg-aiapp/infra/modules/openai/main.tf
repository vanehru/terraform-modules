# Azure OpenAI Service
resource "azurerm_cognitive_account" "openai" {
  name                = var.openai_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = var.sku_name

  custom_subdomain_name         = var.custom_subdomain_name != null ? var.custom_subdomain_name : var.openai_account_name
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = var.enable_network_acls ? [1] : []
    content {
      default_action = var.network_acls_default_action
      ip_rules       = var.allowed_ip_ranges
      virtual_network_rules {
        subnet_id = var.allowed_subnet_id
      }
    }
  }

  tags = var.tags
}

# OpenAI Deployments (Models)
resource "azurerm_cognitive_deployment" "deployment" {
  for_each             = var.deployments
  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = "Standard"
    tier     = "Standard"
    capacity = each.value.capacity
  }
}

# Private Endpoint for OpenAI
resource "azurerm_private_endpoint" "openai_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.openai_account_name}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.openai_account_name}-connection"
    private_connection_resource_id = azurerm_cognitive_account.openai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private DNS Zone for OpenAI
resource "azurerm_private_dns_zone" "openai_dns" {
  count               = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "openai_dns_link" {
  count                 = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                  = "${var.openai_account_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.openai_dns[0].name
  virtual_network_id    = var.virtual_network_id

  tags = var.tags
}

# DNS A record for OpenAI's private endpoint
resource "azurerm_private_dns_a_record" "openai_dns_a_record" {
  count               = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                = var.openai_account_name
  zone_name           = azurerm_private_dns_zone.openai_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.openai_endpoint[0].private_service_connection[0].private_ip_address]

  tags = var.tags
}
