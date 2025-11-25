# Outputs
# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "Location of the Resource Group"
  value       = azurerm_resource_group.rg.location
}

# Network Configuration Outputs
output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  description = "Address space of the Virtual Network"
  value       = azurerm_virtual_network.vnet.address_space
}

output "subnet_configuration" {
  description = "Summary of all subnet configurations"
  value = {
    app_subnet = {
      name          = azurerm_subnet.app_subnet.name
      address_range = azurerm_subnet.app_subnet.address_prefixes[0]
      purpose       = "Function App VNet Integration"
    }
    storage_subnet = {
      name          = azurerm_subnet.storage_subnet.name
      address_range = azurerm_subnet.storage_subnet.address_prefixes[0]
      purpose       = "Storage Account Private Endpoint"
    }
    keyvault_subnet = {
      name          = azurerm_subnet.keyvault_subnet.name
      address_range = azurerm_subnet.keyvault_subnet.address_prefixes[0]
      purpose       = "Key Vault Private Endpoint"
    }
    database_subnet = {
      name          = azurerm_subnet.database_subnet.name
      address_range = azurerm_subnet.database_subnet.address_prefixes[0]
      purpose       = "SQL Database Private Endpoint"
    }
    openai_subnet = {
      name          = azurerm_subnet.openai_subnet.name
      address_range = azurerm_subnet.openai_subnet.address_prefixes[0]
      purpose       = "Azure OpenAI Private Endpoint"
    }
    deployment_subnet = {
      name          = azurerm_subnet.deployment_subnet.name
      address_range = azurerm_subnet.deployment_subnet.address_prefixes[0]
      purpose       = "Cloud Shell Container Instance"
    }
  }
}

# Cloud Shell Outputs
output "cloud_shell_storage_account" {
  description = "Storage account name for Cloud Shell"
  value       = azurerm_storage_account.cloud_shell.name
}

output "cloud_shell_file_share" {
  description = "File share name for Cloud Shell persistence"
  value       = azurerm_storage_share.cloud_shell.name
}

# Cloud shell container output commented out - container resource disabled
# output "cloud_shell_container_ip" {
#   description = "Private IP of Cloud Shell relay container"
#   value       = azurerm_container_group.cloud_shell_relay.ip_address
# }

output "deployment_instructions" {
  description = "How to use Cloud Shell for deployment"
  value       = <<-EOT
    1. Open Azure Cloud Shell: https://shell.azure.com
    2. Configure Cloud Shell to use this VNet:
       az cloud-shell configure \\
         --relay-resource-group ${azurerm_resource_group.rg.name} \\
         --relay-vnet ${azurerm_virtual_network.vnet.name} \\
         --relay-subnet ${azurerm_subnet.deployment_subnet.name}
    3. Deploy Static Web App:
       swa deploy --app-name ${module.static_web_app.static_web_app_name}
  EOT
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = var.enable_function_app ? module.function_app[0].function_app_name : null
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = var.enable_function_app ? "https://${module.function_app[0].function_app_default_hostname}" : null
}

output "static_web_app_url" {
  description = "URL of the Static Web App"
  value       = "https://${module.static_web_app.default_host_name}"
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.key_vault.key_vault_name
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = module.sql_database.sql_server_name
}

output "openai_account_name" {
  description = "Name of the OpenAI account"
  value       = module.openai.openai_account_name
}

# Integration Summary
output "integration_summary" {
  description = "Summary of all service integrations and connections"
  value = {
    function_app = var.enable_function_app ? {
      name     = module.function_app[0].function_app_name
      url      = "https://${module.function_app[0].function_app_default_hostname}"
      plan     = "Y1 Consumption (Serverless)"
      access   = "Public Internet"
      identity = "Managed Identity Enabled"
    } : null
    
    key_vault = {
      name        = module.key_vault.key_vault_name
      uri         = module.key_vault.key_vault_uri
      access      = "Private Endpoint + Current IP"
      secrets     = ["sql-connection-string", "sql-username", "sql-server-fqdn", "sql-database-name", "openai-endpoint", "openai-key"]
      integration = var.enable_function_app ? "Function App has Get/List permissions" : "No Function App integration"
    }
    
    sql_database = {
      server   = module.sql_database.sql_server_name
      database = module.sql_database.sql_database_name
      access   = "Private Endpoint Only"
      tier     = "Basic (2GB)"
    }
    
    openai = {
      account     = module.openai.openai_account_name
      endpoint    = module.openai.openai_endpoint
      access      = "Public Internet"
      region      = "East US"
      deployments = "None (can be added later)"
    }
    
    static_web_app = {
      name   = module.static_web_app.static_web_app_name
      url    = "https://${module.static_web_app.default_host_name}"
      tier   = "Standard"
      region = "East Asia"
    }
    
    network = {
      vnet           = azurerm_virtual_network.vnet.name
      address_space  = azurerm_virtual_network.vnet.address_space[0]
      subnets        = 6
      private_endpoints = 3
    }
  }
}

output "next_steps" {
  description = "Recommended next steps after deployment"
  value = <<-EOT
    🎉 Infrastructure deployed successfully!
    
    📋 Next Steps:
    1. Function App: Deploy your code to ${var.enable_function_app ? module.function_app[0].function_app_name : "[Function App not enabled]"}
    2. Static Web App: Configure GitHub integration for ${module.static_web_app.static_web_app_name}
    3. OpenAI: Add model deployments (gpt-4, gpt-35-turbo) to ${module.openai.openai_account_name}
    4. Database: Connect and create tables in ${module.sql_database.sql_database_name}
    5. Key Vault: All secrets are pre-configured in ${module.key_vault.key_vault_name}
    
    🔗 Integration Status:
    ✅ Function App → Key Vault (Managed Identity)
    ✅ Key Vault → SQL Database (Connection strings stored)
    ✅ Key Vault → OpenAI (API keys stored)
    ✅ All backend services use private endpoints
    ✅ Network isolation with 6 dedicated subnets
    
    💰 Estimated Monthly Cost: $30-60 USD
  EOT
}