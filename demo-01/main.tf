terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 4.8.0"
    }
  }
  required_version = ">=1.9.0"
}

provider "azurerm" {
  resource_provider_registrations = "none" 
  features {}
}

resource "azurerm_resource_group" "terraform-demo" {
  name     = "terraform-demo-resources"
  location = "central india"
}

resource "azurerm_storage_account" "terraform-demo" {
 
  name                     = "demo1017"
  resource_group_name      = azurerm_resource_group.terraform-demo.name
  location                 = azurerm_resource_group.terraform-demo.location # implicit dependency
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "staging"
  }
}