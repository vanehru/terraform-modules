# Azure OpenAI Service Module

resource "azurerm_cognitive_account" "openai" {
  name                          = var.account_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  kind                          = "OpenAI"
  sku_name                      = var.sku_name
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags
}

resource "azurerm_cognitive_deployment" "deployment" {
  name                 = var.deployment_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.model_name
    version = var.model_version
  }

  scale {
    type     = var.scale_type
    capacity = var.capacity
  }

  version_upgrade_option = var.version_upgrade_option
}
