terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli = true
}

resource "azurerm_resource_group" "test" {
  name     = "test-sql-rg"
  location = "West US 2"
}

module "sql_database" {
  source = "../"

  sql_server_name      = "testsql${random_id.test.hex}"
  resource_group_name  = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  admin_username      = "sqladmin"
  admin_password      = "P@ssw0rd1234!"
  database_name       = "testdb"
  sku_name            = "Basic"
  max_size_gb         = 2
  
  public_network_access_enabled = true
  allow_azure_services = true
  firewall_rules = {
    "test_client" = {
      start_ip = "219.104.25.254"
      end_ip   = "219.104.25.254"
    }
  }
}

resource "random_id" "test" {
  byte_length = 4
}

output "connection_string" {
  value     = module.sql_database.connection_string
  sensitive = true
}