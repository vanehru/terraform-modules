# Key Vault
resource "azurerm_key_vault" "kv" {
  name                     = var.key_vault_name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  tenant_id                = var.tenant_id
  sku_name                 = var.sku_name
  purge_protection_enabled = var.purge_protection_enabled
  
  # Security configurations
  soft_delete_retention_days      = 7
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  rbac_authorization_enabled      = false

  network_acls {
    default_action             = var.network_acls_default_action
    bypass                     = var.network_acls_bypass
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  dynamic "access_policy" {
    for_each = var.access_policies
    content {
      tenant_id          = var.tenant_id
      object_id          = access_policy.value.object_id
      secret_permissions = access_policy.value.secret_permissions
      key_permissions    = access_policy.value.key_permissions
      certificate_permissions = access_policy.value.certificate_permissions
    }
  }

  tags = var.tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "kv_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.key_vault_name}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.key_vault_name}-connection"
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "kv_dns" {
  count               = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link DNS zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "kv_dns_link" {
  count                 = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                  = "${var.key_vault_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns[0].name
  virtual_network_id    = var.virtual_network_id

  tags = var.tags
}

# DNS A record for Key Vault's private endpoint
resource "azurerm_private_dns_a_record" "kv_dns_a_record" {
  count               = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                = var.key_vault_name
  zone_name           = azurerm_private_dns_zone.kv_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.kv_endpoint[0].private_service_connection[0].private_ip_address]

  tags = var.tags
}

# Key Vault Secrets
resource "azurerm_key_vault_secret" "secrets" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}
