terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
  required_version = ">= 1.9.0"
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Generate random suffix for storage account name (must be globally unique)
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

# Local values for better organization
locals {
  common_tags = merge(
    var.tags,
    {
      environment   = var.environment
      project       = var.project_name
      created_by    = "terraform"
      creation_date = formatdate("YYYY-MM-DD", timestamp())
    }
  )
  
  storage_account_name = "${replace(var.project_name, "-", "")}${var.environment}${random_string.storage_suffix.result}"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = local.common_tags
  
  lifecycle {
    create_before_destroy = true
  }
}

# Storage Account with enhanced security
resource "azurerm_storage_account" "main" {
  name                = local.storage_account_name
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  account_kind            = "StorageV2"
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  
  # Enable blob properties
  blob_properties {
    versioning_enabled       = true
    change_feed_enabled      = true
    change_feed_retention_in_days = 7
    last_access_time_enabled = true
    
    delete_retention_policy {
      days = 7
    }
    
    container_delete_retention_policy {
      days = 7
    }
  }
  
  tags = local.common_tags
  
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["creation_date"]
    ]
  }
}