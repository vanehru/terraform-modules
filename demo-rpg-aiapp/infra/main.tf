# Local values for consistent tagging and naming
locals {
  common_tags = {
    project_owner = var.project_owner
    author        = var.author
    environment   = var.environment
    project       = "rpg-aiapp"
    managed_by    = "terraform"
    created_date  = formatdate("YYYY-MM-DD", timestamp())
  }
  
  name_prefix = "${var.environment}-rpg"
}

resource "azurerm_resource_group" "rg" {
  name     = var.azurerm_resource_group_name
  location = var.azurerm_resource_group_location

  tags = local.common_tags
}

# VNet and subnets with enhanced security
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name_prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = local.common_tags
}

# Network Security Group for Application Subnet
resource "azurerm_network_security_group" "app_nsg" {
  name                = "${local.name_prefix}-app-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Subnet 1: Application Subnet (Static Web App + Function App)
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.app_subnet_cidr]

  service_endpoints = ["Microsoft.Web", "Microsoft.KeyVault", "Microsoft.Storage"]

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

# Associate NSG with App Subnet
resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

# Subnet 2: Storage Subnet (Storage Account Private Endpoint)
resource "azurerm_subnet" "storage_subnet" {
  name                 = "storage-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.storage_subnet_cidr]

  service_endpoints = ["Microsoft.Storage"]
}

# Subnet 3: Key Vault Subnet (Key Vault Private Endpoint)
resource "azurerm_subnet" "keyvault_subnet" {
  name                 = "keyvault-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.keyvault_subnet_cidr]

  service_endpoints = ["Microsoft.KeyVault"]
}

# Subnet 4: Database Subnet (SQL Database Private Endpoint)
resource "azurerm_subnet" "database_subnet" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.database_subnet_cidr]

  service_endpoints = ["Microsoft.Sql"]
}

# Subnet 5: OpenAI Subnet (OpenAI Private Endpoint)
resource "azurerm_subnet" "openai_subnet" {
  name                 = "openai-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.openai_subnet_cidr]
}

# Subnet 6: Deployment Subnet (Cloud Shell Container Instance)
resource "azurerm_subnet" "deployment_subnet" {
  name                 = "deployment-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.deployment_subnet_cidr]

  service_endpoints = ["Microsoft.Storage"]

  delegation {
    name = "container-delegation"
    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

# Random password for SQL Server with enhanced security
resource "random_password" "sql_admin_password" {
  length      = 32
  special     = true
  min_lower   = 2
  min_upper   = 2
  min_numeric = 2
  min_special = 2
  
  lifecycle {
    ignore_changes = [length, special, min_lower, min_upper, min_numeric, min_special]
  }
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name              = "${replace(local.name_prefix, "-", "")}kv123"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  network_acls_default_action = "Deny"
  network_acls_bypass         = "AzureServices"
  allowed_subnet_ids          = [azurerm_subnet.app_subnet.id, azurerm_subnet.keyvault_subnet.id]

  access_policies = [
    {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
    }
  ]

  # Store SQL and OpenAI secrets
  secrets = {
    "sql-connection-string" = module.sql_database.connection_string
    "sql-username"          = module.sql_database.admin_username
    "sql-server-fqdn"       = module.sql_database.sql_server_fqdn
    "sql-database-name"     = module.sql_database.sql_database_name
    "openai-endpoint"       = module.openai.openai_endpoint
    "openai-key"            = module.openai.openai_primary_key
  }

  depends_on = [
    module.sql_database,
    module.openai
  ]

  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.keyvault_subnet.id
  create_private_dns_zone    = true
  virtual_network_id         = azurerm_virtual_network.vnet.id

  tags = local.common_tags
}

# SQL Database Module
module "sql_database" {
  source = "./modules/sql-database"

  sql_server_name               = "${local.name_prefix}-sql-server"
  database_name                 = "${local.name_prefix}-db"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  admin_username                = "sqladmin"
  admin_password                = random_password.sql_admin_password.result
  sql_server_version            = "12.0"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  sku_name                      = "Basic"
  max_size_gb                   = 1
  allow_azure_services          = false
  subnet_id                     = azurerm_subnet.database_subnet.id
  enable_private_endpoint       = true
  private_endpoint_subnet_id    = azurerm_subnet.database_subnet.id
  create_private_dns_zone       = true
  virtual_network_id            = azurerm_virtual_network.vnet.id

  tags = local.common_tags
}

# OpenAI Module
module "openai" {
  source = "./modules/openai"

  openai_account_name           = "${local.name_prefix}-ai-svc"
  location                      = "Japan East"
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = "S0"
  public_network_access_enabled = false
  enable_private_endpoint       = true
  private_endpoint_subnet_id    = azurerm_subnet.openai_subnet.id
  create_private_dns_zone       = true
  virtual_network_id            = azurerm_virtual_network.vnet.id

  # Deploy current GPT models
  deployments = {
    "gpt-4o" = {
      model_name    = "gpt-4o"
      model_version = "2024-11-20"
      scale_type    = "Standard"
      capacity      = 1
    }
  }

  tags = local.common_tags
}

# App Service Plan for Function App
resource "azurerm_service_plan" "function_plan" {
  name                = "${local.name_prefix}-func-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = local.common_tags
}



# Storage Account for Function App (Public Access)
resource "azurerm_storage_account" "function_storage" {
  name                     = "${replace(local.name_prefix, "-", "")}func123"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = local.common_tags
}

# Function App (Public Access)
resource "azurerm_linux_function_app" "function_app" {
  name                = "${local.name_prefix}-func"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.function_plan.id

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"    = "python"
    "FUNCTIONS_EXTENSION_VERSION" = "~4"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  tags = local.common_tags
}

# Static Web App Module
module "static_web_app" {
  source = "./modules/static-web-app"

  static_web_app_name = "${local.name_prefix}-web"
  location            = "East Asia"
  resource_group_name = azurerm_resource_group.rg.name
  sku_tier            = "Free"
  sku_size            = "Free"
  function_app_id     = null

  tags = local.common_tags
}

# Storage Account for Cloud Shell with enhanced security
resource "azurerm_storage_account" "cloud_shell" {
  name                     = "${replace(local.name_prefix, "-", "")}cloudshell123"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Security configurations
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  https_traffic_only_enabled      = true
  
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }

  depends_on = [azurerm_subnet.deployment_subnet]

  tags = merge(local.common_tags, {
    purpose = "cloud-shell-storage"
  })
}

# File share for Cloud Shell persistence
resource "azurerm_storage_share" "cloud_shell" {
  name                 = "cloudshell"
  storage_account_name = azurerm_storage_account.cloud_shell.name
  quota                = 6 # 6 GB for Cloud Shell
}

# Container Instance for Cloud Shell VNet relay
resource "azurerm_container_group" "cloud_shell_relay" {
  name                = "cloudshell-relay"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Private"

  # Network configuration
  subnet_ids = [azurerm_subnet.deployment_subnet.id]

  depends_on = [
    azurerm_subnet.deployment_subnet,
    azurerm_virtual_network.vnet
  ]

  # Identity for Azure authentication
  identity {
    type = "SystemAssigned"
  }

  container {
    name   = "cloud-shell-relay"
    image  = "mcr.microsoft.com/azure-cli:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }

    # Keep container running
    commands = [
      "/bin/sh",
      "-c",
      "while true; do sleep 3600; done"
    ]

    # Environment variables for Azure tools
    environment_variables = {
      "AZURE_SUBSCRIPTION_ID" = data.azurerm_client_config.current.subscription_id
    }
  }

  tags = merge(local.common_tags, {
    purpose = "cloud-shell-vnet-relay"
  })
}

# Get Azure AD info for access policies
data "azurerm_client_config" "current" {}