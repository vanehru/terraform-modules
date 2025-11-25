# Azure Static Web App Module

resource "azurerm_static_web_app" "app" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_size            = var.sku_size
  sku_tier            = var.sku_tier
  tags                = var.tags
}
