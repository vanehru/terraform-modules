# Azure SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.sql_server_version
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  minimum_tls_version          = var.minimum_tls_version

  dynamic "azuread_administrator" {
    for_each = var.azuread_admin_login != null && var.azuread_admin_object_id != null ? [1] : []
    content {
      login_username = var.azuread_admin_login
      object_id      = var.azuread_admin_object_id
    }
  }

  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags
}

# Azure SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.sql_server.id
  collation      = var.collation
  sku_name       = var.sku_name
  max_size_gb    = var.max_size_gb
  zone_redundant = var.zone_redundant

  tags = var.tags
}

# Firewall Rules
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  count            = var.allow_azure_services ? 1 : 0
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_firewall_rule" "custom_rules" {
  for_each         = var.firewall_rules
  name             = each.key
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}

# Virtual Network Rule (optional - will be created if subnet_id is provided in variables)
# Note: This resource is commented out to avoid count dependency issues with computed values
# Enable this after initial infrastructure creation, or create manually via Azure Portal/CLI
# resource "azurerm_mssql_virtual_network_rule" "vnet_rule" {
#   name      = "${var.sql_server_name}-vnet-rule"
#   server_id = azurerm_mssql_server.sql_server.id
#   subnet_id = var.subnet_id
# }

# Private Endpoint for SQL Server
resource "azurerm_private_endpoint" "sql_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.sql_server_name}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.sql_server_name}-connection"
    private_connection_resource_id = azurerm_mssql_server.sql_server.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Private DNS Zone for SQL Server
resource "azurerm_private_dns_zone" "sql_dns" {
  count               = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  count                 = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                  = "${var.sql_server_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns[0].name
  virtual_network_id    = var.virtual_network_id

  tags = var.tags
}

# DNS A record for SQL Server's private endpoint
resource "azurerm_private_dns_a_record" "sql_dns_a_record" {
  count               = var.enable_private_endpoint && var.create_private_dns_zone ? 1 : 0
  name                = var.sql_server_name
  zone_name           = azurerm_private_dns_zone.sql_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql_endpoint[0].private_service_connection[0].private_ip_address]

  tags = var.tags
}
