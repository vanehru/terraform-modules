# Azure Static Web App
resource "azurerm_static_web_app" "swa" {
  name                = var.static_web_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_tier            = var.sku_tier
  sku_size            = var.sku_size

  tags = var.tags
}

# Link Static Web App with Function App
resource "azurerm_static_web_app_function_app_registration" "swa_function_link" {
  count               = var.function_app_id != null && var.function_app_id != "" ? 1 : 0
  static_web_app_id   = azurerm_static_web_app.swa.id
  function_app_id     = var.function_app_id
  
  depends_on = [azurerm_static_web_app.swa]
}

# Custom Domain (optional)
resource "azurerm_static_web_app_custom_domain" "custom_domain" {
  count             = var.custom_domain_name != null ? 1 : 0
  static_web_app_id = azurerm_static_web_app.swa.id
  domain_name       = var.custom_domain_name
  validation_type   = var.validation_type
}
