# Function App Module

This module creates an Azure Function App with configurable hosting plans, managed identity, and optional VNet integration.

## Features

- **Flexible Hosting Plans**: Supports Consumption (Y1), Elastic Premium (EP1-EP3), and Premium (P1v2-P3v2) plans
- **Managed Identity**: User-assigned managed identity for secure access to Azure services
- **VNet Integration**: Optional VNet integration for Premium/Elastic Premium plans
- **Private Endpoints**: Optional private endpoint for storage account
- **Multiple Runtimes**: Supports .NET, Python, Node.js, Java, and PowerShell

## Usage

### Consumption Plan (Y1) - Cost-Effective for Development

```hcl
module "function_app" {
  source = "./modules/function-app"

  function_app_name                = "my-func-app"
  location                         = "East US"
  resource_group_name              = "my-rg"
  storage_account_name             = "myfuncstorage"
  app_service_plan_name            = "my-consumption-plan"
  app_service_plan_sku             = "Y1"  # Consumption plan
  
  # Managed Identity for Key Vault access
  create_managed_identity          = true
  
  # VNet integration NOT supported on Consumption plan
  enable_vnet_integration          = false
  vnet_route_all_enabled           = false
  
  # Storage account configuration
  storage_public_network_access_enabled = true  # Required for Consumption plan
  storage_network_default_action        = "Allow"
  
  # Application stack (.NET for C++ code)
  application_stack = {
    dotnet_version = "8.0"
  }
  
  app_settings = {
    "KEY_VAULT_URI" = "https://my-keyvault.vault.azure.net/"
  }
}
```

### Premium Plan (P1v2) - With VNet Integration

```hcl
module "function_app" {
  source = "./modules/function-app"

  function_app_name                = "my-func-app"
  location                         = "East US"
  resource_group_name              = "my-rg"
  storage_account_name             = "myfuncstorage"
  app_service_plan_name            = "my-premium-plan"
  app_service_plan_sku             = "P1v2"  # Premium plan
  
  # Managed Identity
  create_managed_identity          = true
  
  # VNet integration (Premium plan feature)
  enable_vnet_integration          = true
  vnet_integration_subnet_id       = azurerm_subnet.app_subnet.id
  vnet_route_all_enabled           = true
  
  # Storage account with private endpoint
  storage_public_network_access_enabled = false
  storage_network_default_action        = "Deny"
  storage_allowed_subnet_ids            = [azurerm_subnet.app_subnet.id]
  enable_storage_private_endpoint       = true
  storage_private_endpoint_subnet_id    = azurerm_subnet.storage_subnet.id
  create_storage_private_dns_zone       = true
  storage_virtual_network_id            = azurerm_virtual_network.vnet.id
  
  # Application stack
  application_stack = {
    dotnet_version = "8.0"
  }
  
  app_settings = {
    "KEY_VAULT_URI" = "https://my-keyvault.vault.azure.net/"
  }
}
```

## Plan Comparison

| Feature | Consumption (Y1) | Elastic Premium (EP1) | Premium (P1v2) |
|---------|------------------|----------------------|----------------|
| **Cost** | ~$0-20/month (pay per execution) | ~$150/month | ~$146/month |
| **VNet Integration** | ❌ Not supported | ✅ Supported | ✅ Supported |
| **Private Endpoints** | ❌ Not supported | ✅ Supported | ✅ Supported |
| **Always On** | ❌ No | ✅ Yes | ✅ Yes |
| **Cold Start** | ⚠️ Yes | ⚠️ Minimal | ❌ No |
| **Max Execution Time** | 5 minutes (default) | 30 minutes | 30 minutes |
| **Managed Identity** | ✅ Supported | ✅ Supported | ✅ Supported |
| **Storage Account** | Public access required | Private endpoint supported | Private endpoint supported |
| **Best For** | Development, low-traffic | Production, variable load | Production, consistent load |

## Cost Implications

### Consumption Plan (Y1)
- **Monthly Cost**: $0-20 (based on executions)
- **Execution Cost**: $0.20 per million executions
- **Memory Cost**: $0.000016/GB-s
- **Free Grant**: 1 million executions and 400,000 GB-s per month
- **Trade-offs**: 
  - ❌ No VNet integration
  - ❌ No private endpoints
  - ⚠️ Cold start delays
  - ✅ Very cost-effective for development

### Premium Plan (P1v2)
- **Monthly Cost**: ~$146
- **Includes**: 
  - ✅ VNet integration
  - ✅ Private endpoints
  - ✅ Always on (no cold starts)
  - ✅ Better performance
- **Trade-offs**:
  - ❌ Higher fixed cost
  - ✅ Predictable billing

## Application Stacks

### .NET (for C++ code)
```hcl
application_stack = {
  dotnet_version = "8.0"  # or "6.0", "7.0"
}
```

### Python
```hcl
application_stack = {
  python_version = "3.11"  # or "3.9", "3.10"
}
```

### Node.js
```hcl
application_stack = {
  node_version = "20"  # or "18", "16"
}
```

### Java
```hcl
application_stack = {
  java_version = "17"  # or "11", "8"
}
```

### PowerShell
```hcl
application_stack = {
  powershell_core_version = "7.2"
}
```

## Managed Identity

The module creates a user-assigned managed identity that can be used to access Azure services without storing credentials:

```hcl
# In your Function App code (C#/.NET example)
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var credential = new DefaultAzureCredential();
var client = new SecretClient(
    new Uri(Environment.GetEnvironmentVariable("KEY_VAULT_URI")),
    credential
);

var secret = await client.GetSecretAsync("my-secret");
```

## Storage Account Configuration

### For Consumption Plan (Y1)
```hcl
storage_public_network_access_enabled = true
storage_network_default_action        = "Allow"
enable_storage_private_endpoint       = false
```

### For Premium Plan (P1v2/EP1)
```hcl
storage_public_network_access_enabled = false
storage_network_default_action        = "Deny"
storage_allowed_subnet_ids            = [azurerm_subnet.app_subnet.id]
enable_storage_private_endpoint       = true
storage_private_endpoint_subnet_id    = azurerm_subnet.storage_subnet.id
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| function_app_name | Name of the Function App | string | - | yes |
| location | Azure region | string | - | yes |
| resource_group_name | Resource group name | string | - | yes |
| storage_account_name | Storage account name | string | - | yes |
| app_service_plan_name | App Service Plan name | string | - | yes |
| app_service_plan_sku | SKU (Y1, EP1, P1v2, etc.) | string | "Y1" | no |
| create_managed_identity | Create managed identity | bool | true | no |
| enable_vnet_integration | Enable VNet integration | bool | false | no |
| vnet_integration_subnet_id | Subnet ID for VNet integration | string | null | no |
| application_stack | Application runtime stack | object | null | no |
| app_settings | Application settings | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| function_app_id | Function App resource ID |
| function_app_name | Function App name |
| function_app_default_hostname | Function App hostname |
| function_app_identity_principal_id | Managed identity principal ID |
| function_app_identity_id | Managed identity resource ID |
| storage_account_id | Storage account resource ID |
| storage_account_name | Storage account name |

## Examples

See the [examples](../../examples/) directory for complete examples.

## Notes

- **Consumption Plan Limitations**: VNet integration and private endpoints are NOT supported on Y1 (Consumption) plan
- **Storage Account**: Consumption plan requires public access to storage account
- **Managed Identity**: Works on all plan types and is recommended for accessing Key Vault
- **Cold Starts**: Consumption plan has cold start delays; use Premium for production workloads requiring consistent performance
- **.NET Stack**: Use `dotnet_version = "8.0"` for C++ code compiled to .NET assemblies

## Security Recommendations

### For Development (Consumption Plan)
1. ✅ Use managed identity for Key Vault access
2. ✅ Store all secrets in Key Vault
3. ⚠️ Accept public access to Function App (no VNet integration available)
4. ⚠️ Accept public access to storage account (required for Consumption plan)
5. ✅ Use network ACLs on Key Vault to restrict access

### For Production (Premium Plan)
1. ✅ Use managed identity for Key Vault access
2. ✅ Enable VNet integration
3. ✅ Enable private endpoints for storage account
4. ✅ Route all traffic through VNet
5. ✅ Use network ACLs on all services
6. ✅ Implement NSGs on subnets

## Troubleshooting

### Function App won't start
- Check that storage account is accessible (public for Y1, private endpoint for Premium)
- Verify managed identity has access to Key Vault
- Check application settings are correct

### VNet integration not working
- Verify you're using Premium (P1v2) or Elastic Premium (EP1) plan, not Consumption (Y1)
- Check subnet has Microsoft.Web/serverFarms delegation
- Verify subnet has available IP addresses

### Storage account access denied
- For Consumption plan: Ensure public access is enabled
- For Premium plan: Verify private endpoint is created and DNS is configured
- Check network ACLs allow the Function App subnet

## References

- [Azure Functions hosting options](https://docs.microsoft.com/en-us/azure/azure-functions/functions-scale)
- [Azure Functions networking options](https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options)
- [Managed identities for Azure Functions](https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity)
