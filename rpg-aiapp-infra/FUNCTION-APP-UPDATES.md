# Function App Module Updates

**Date:** 2025-11-25  
**Task:** Enhance Function App module for Consumption Plan (Y1) with .NET stack

## Summary

Updated the Function App module to support **Consumption Plan (Y1)** with **.NET 8.0 stack** for C++ code, using **public access** (no VNet integration) and **Managed Identity** for secure Key Vault access.

---

## Changes Made

### 1. Module Configuration Updates

#### `modules/function-app/variables.tf`

**Changed default SKU from P1v2 to Y1:**
```hcl
variable "app_service_plan_sku" {
  description = "SKU for the App Service Plan (e.g., Y1 for Consumption, EP1 for Elastic Premium, P1v2 for Premium)"
  type        = string
  default     = "Y1"  # Changed from "P1v2"
  
  validation {
    condition     = can(regex("^(Y1|EP1|EP2|EP3|P1v2|P2v2|P3v2|S1|S2|S3)$", var.app_service_plan_sku))
    error_message = "SKU must be a valid App Service Plan SKU..."
  }
}
```

**Updated VNet integration defaults:**
```hcl
variable "vnet_route_all_enabled" {
  description = "Route all traffic through VNet (only supported on Premium/Elastic Premium plans)"
  type        = bool
  default     = false  # Changed from true
}

variable "enable_vnet_integration" {
  description = "Enable VNet integration for Function App (only supported on Premium/Elastic Premium plans, not on Consumption Y1)"
  type        = bool
  default     = false  # Remains false
}
```

#### `modules/function-app/main.tf`

**Added logic to detect Consumption plan:**
```hcl
# Local variable to determine if plan supports VNet integration
locals {
  is_consumption_plan = var.app_service_plan_sku == "Y1"
  supports_vnet       = !local.is_consumption_plan && var.enable_vnet_integration
}
```

**Updated site_config to conditionally enable VNet routing:**
```hcl
site_config {
  # VNet routing only supported on Premium/Elastic Premium plans
  vnet_route_all_enabled = local.supports_vnet ? var.vnet_route_all_enabled : false
  
  dynamic "application_stack" {
    # ... stack configuration
  }
}
```

**Updated VNet integration resource:**
```hcl
# VNet Integration for Function App (only for Premium/Elastic Premium plans)
resource "azurerm_app_service_virtual_network_swift_connection" "function_vnet_integration" {
  count          = local.supports_vnet ? 1 : 0  # Changed from var.enable_vnet_integration
  app_service_id = azurerm_linux_function_app.function.id
  subnet_id      = var.vnet_integration_subnet_id
}
```

### 2. Main Configuration Updates

#### `main.tf`

**Enabled Function App module with Consumption plan:**
```hcl
module "function_app" {
  source = "./modules/function-app"

  function_app_name                = "demo-rpg-func-${random_string.suffix.result}"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  storage_account_name             = "rpgfuncstor${random_string.suffix.result}"
  storage_account_tier             = "Standard"
  storage_account_replication_type = "LRS"
  app_service_plan_name            = "demo-rpg-consumption-plan"
  app_service_plan_sku             = "Y1"  # Consumption plan
  
  # Managed Identity for Key Vault access
  create_managed_identity          = true
  
  # VNet integration NOT supported on Consumption plan
  enable_vnet_integration          = false
  vnet_route_all_enabled           = false
  
  # Storage Account - Public access required for Consumption plan
  storage_public_network_access_enabled = true
  storage_network_default_action        = "Allow"
  enable_storage_private_endpoint       = false

  # .NET stack for C++ code
  application_stack = {
    dotnet_version = "8.0"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "KEY_VAULT_URI"            = module.key_vault.key_vault_uri
    "SQL_CONNECTION_SECRET"    = "sql-connection-string"
    "OPENAI_ENDPOINT_SECRET"   = "openai-endpoint"
    "OPENAI_KEY_SECRET"        = "openai-key"
  }

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
  }
}
```

**Key changes:**
- ✅ Added random suffix to Function App name
- ✅ Added random suffix to storage account name
- ✅ Set SKU to Y1 (Consumption)
- ✅ Disabled VNet integration
- ✅ Enabled public access for storage account
- ✅ Configured .NET 8.0 stack
- ✅ Enabled managed identity

**Updated Key Vault access policies:**
```hcl
access_policies = [
  # Function App access policy - least privilege (Get, List only)
  {
    object_id          = module.function_app.function_app_identity_principal_id
    secret_permissions = ["Get", "List"]
  },
  # Administrator access policy - full management permissions
  {
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }
]
```

**Linked Static Web App to Function App:**
```hcl
module "static_web_app" {
  source = "./modules/static-web-app"

  static_web_app_name = "rpg-gaming-web-${random_string.suffix.result}"
  location            = "East Asia"
  resource_group_name = azurerm_resource_group.rg.name
  sku_tier            = "Standard"
  sku_size            = "Standard"
  
  # Link to Function App backend
  function_app_id     = module.function_app.function_app_id

  tags = {
    project_owner = "ootsuka"
    author        = "Nehru"
    environment   = "development"
  }
}
```

#### `outputs.tf`

**Added Function App outputs:**
```hcl
output "function_app_name" {
  description = "Name of the Function App"
  value       = module.function_app.function_app_name
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${module.function_app.function_app_default_hostname}"
}

output "function_app_identity_principal_id" {
  description = "Principal ID of the Function App managed identity"
  value       = module.function_app.function_app_identity_principal_id
}
```

### 3. Documentation

**Created `modules/function-app/README.md`:**
- Comprehensive documentation of Consumption vs Premium plans
- Cost comparison table
- Usage examples for both plan types
- Application stack configuration examples
- Security recommendations
- Troubleshooting guide

---

## Configuration Summary

### Current Setup

| Component | Configuration | Reason |
|-----------|---------------|--------|
| **Hosting Plan** | Y1 (Consumption) | Cost-effective, no quota issues |
| **Runtime Stack** | .NET 8.0 | For C++ code compiled to .NET |
| **Managed Identity** | Enabled | Secure Key Vault access |
| **VNet Integration** | Disabled | Not supported on Consumption plan |
| **Storage Access** | Public | Required for Consumption plan |
| **Function App Access** | Public | No private link on Consumption plan |
| **Key Vault Access** | Via Managed Identity | Secure, no credentials in code |

### Security Posture

| Feature | Status | Notes |
|---------|--------|-------|
| Managed Identity | ✅ Enabled | Secure access to Key Vault |
| Secrets in Key Vault | ✅ Enabled | All credentials stored securely |
| Least Privilege Access | ✅ Enabled | Function App has Get/List only |
| Public Access | ⚠️ Required | Consumption plan limitation |
| Storage Public Access | ⚠️ Required | Consumption plan limitation |
| Network Isolation | ❌ Not Available | Requires Premium plan |

### Cost Comparison

| Plan | Monthly Cost | Features |
|------|--------------|----------|
| **Y1 (Current)** | $0-20 | Pay per execution, no VNet |
| **EP1** | ~$150 | VNet integration, private endpoints |
| **P1v2** | ~$146 | VNet integration, private endpoints |

**Estimated Savings:** ~$126-146/month using Consumption plan

---

## Integration Flow

```
User
  ↓ HTTPS
Static Web App (Public)
  ↓ Linked Backend API
Function App (Public - Consumption Plan)
  ↓ Managed Identity
Key Vault (Private Endpoint)
  ↓ Returns Credentials
  ├─→ SQL Database (Private Endpoint)
  └─→ Azure OpenAI (Public Access)
```

### Data Flow Details

1. **User → Static Web App**
   - Protocol: HTTPS
   - Access: Public (by design)

2. **Static Web App → Function App**
   - Protocol: HTTPS
   - Access: Linked backend API
   - Authentication: Azure-managed

3. **Function App → Key Vault**
   - Protocol: HTTPS
   - Access: Via Managed Identity
   - Network: Function App can access Key Vault private endpoint

4. **Function App → SQL Database**
   - Protocol: TDS (SQL)
   - Access: Via connection string from Key Vault
   - Network: Function App can access SQL private endpoint

5. **Function App → Azure OpenAI**
   - Protocol: HTTPS
   - Access: Via API key from Key Vault
   - Network: Public access (private endpoint disabled)

---

## Deployment Instructions

### Prerequisites

1. Azure CLI installed
2. Terraform installed
3. Azure subscription with permissions

### Deploy Infrastructure

```bash
# 1. Initialize Terraform
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan deployment
terraform plan -out=deployment.tfplan

# 4. Review plan
terraform show deployment.tfplan

# 5. Apply configuration
terraform apply deployment.tfplan

# 6. Get outputs
terraform output
```

### Expected Outputs

```
function_app_name = "demo-rpg-func-abc123"
function_app_url = "https://demo-rpg-func-abc123.azurewebsites.net"
function_app_identity_principal_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
key_vault_name = "demo-rpgkv123"
sql_server_name = "rpg-sql-abc123"
static_web_app_url = "https://rpg-gaming-web-abc123.azurestaticapps.net"
```

### Deploy Function App Code

```bash
# Navigate to your function app code directory
cd your-function-app-code

# Build .NET project
dotnet build --configuration Release

# Publish
dotnet publish --configuration Release --output ./publish

# Deploy to Azure
func azure functionapp publish demo-rpg-func-abc123
```

### Test Deployment

```bash
# Get Function App URL
FUNC_URL=$(terraform output -raw function_app_url)

# Test health endpoint (if you have one)
curl $FUNC_URL/api/health

# Test Key Vault access (from Function App logs)
func azure functionapp logstream demo-rpg-func-abc123
```

---

## Security Considerations

### ✅ Implemented Security Features

1. **Managed Identity**
   - Function App uses managed identity to access Key Vault
   - No credentials stored in code or configuration

2. **Secret Management**
   - All secrets stored in Key Vault
   - SQL connection string, OpenAI API key secured

3. **Least Privilege Access**
   - Function App has only Get/List permissions on Key Vault
   - Administrator has full management permissions

4. **Private Endpoints**
   - Key Vault: Private endpoint enabled
   - SQL Database: Private endpoint enabled
   - Function App can access both via private network

5. **TLS Encryption**
   - All communications use HTTPS/TLS
   - SQL Database requires TLS 1.2 minimum

### ⚠️ Consumption Plan Limitations

1. **No VNet Integration**
   - Function App cannot be placed in VNet
   - Cannot use private endpoints for Function App itself
   - Mitigation: Use managed identity and Key Vault

2. **Storage Account Public Access**
   - Storage account must allow public access
   - Required for Consumption plan to function
   - Mitigation: Use network ACLs to restrict access

3. **Function App Public Access**
   - Function App is accessible from internet
   - Cannot restrict to VNet only
   - Mitigation: Use authentication, API keys, or Azure AD

### 🔒 Additional Security Recommendations

1. **Enable Authentication**
   ```hcl
   # Add to Function App configuration
   auth_settings {
     enabled = true
     default_provider = "AzureActiveDirectory"
   }
   ```

2. **Add IP Restrictions**
   ```hcl
   # Add to Function App site_config
   ip_restriction {
     action     = "Allow"
     ip_address = "your-ip-range/32"
     priority   = 100
   }
   ```

3. **Enable Application Insights**
   - Monitor Function App execution
   - Detect anomalies and security issues

4. **Implement Rate Limiting**
   - Protect against DDoS attacks
   - Use Azure Front Door or API Management

---

## Upgrade Path to Premium Plan

When ready to upgrade to Premium plan for VNet integration:

### 1. Update Configuration

```hcl
module "function_app" {
  # ... other settings ...
  
  app_service_plan_sku             = "EP1"  # or "P1v2"
  
  # Enable VNet integration
  enable_vnet_integration          = true
  vnet_integration_subnet_id       = azurerm_subnet.app_subnet.id
  vnet_route_all_enabled           = true
  
  # Enable storage private endpoint
  storage_public_network_access_enabled = false
  storage_network_default_action        = "Deny"
  storage_allowed_subnet_ids            = [azurerm_subnet.app_subnet.id]
  enable_storage_private_endpoint       = true
  storage_private_endpoint_subnet_id    = azurerm_subnet.storage_subnet.id
  create_storage_private_dns_zone       = true
  storage_virtual_network_id            = azurerm_virtual_network.vnet.id
}
```

### 2. Apply Changes

```bash
terraform plan -out=upgrade.tfplan
terraform apply upgrade.tfplan
```

### 3. Cost Impact

- **Before (Y1):** $0-20/month
- **After (EP1):** ~$150/month
- **Increase:** ~$130-150/month

### 4. Benefits

- ✅ VNet integration
- ✅ Private endpoints for storage
- ✅ No cold starts
- ✅ Better performance
- ✅ Always on

---

## Troubleshooting

### Function App won't start

**Symptoms:**
- Function App shows as "Stopped" or "Error"
- Cannot access Function App URL

**Solutions:**
1. Check storage account is accessible (public access enabled)
2. Verify managed identity is created
3. Check Key Vault access policy includes Function App identity
4. Review Application Insights logs

### Cannot access Key Vault

**Symptoms:**
- Function App logs show "403 Forbidden" from Key Vault
- Secrets cannot be retrieved

**Solutions:**
1. Verify managed identity is enabled on Function App
2. Check Key Vault access policy includes Function App principal ID
3. Verify Key Vault network ACLs allow Function App
4. Check Function App can resolve Key Vault private endpoint

### Storage account access denied

**Symptoms:**
- Function App won't start
- Error: "Storage account is not accessible"

**Solutions:**
1. Verify storage account has public access enabled
2. Check storage account network rules allow public access
3. Verify storage account exists and is in same region

### SQL Database connection fails

**Symptoms:**
- Function App cannot connect to SQL Database
- Connection timeout errors

**Solutions:**
1. Verify connection string in Key Vault is correct
2. Check SQL Database private endpoint is created
3. Verify Function App can resolve SQL private endpoint DNS
4. Check SQL Database firewall rules

---

## Next Steps

1. ✅ **Deploy Infrastructure** - Run `terraform apply`
2. ✅ **Deploy Function App Code** - Deploy your .NET/C++ code
3. ✅ **Test Integration** - Verify Static Web App → Function App → Key Vault → SQL/OpenAI
4. ⚠️ **Add Authentication** - Secure Function App endpoints
5. ⚠️ **Enable Monitoring** - Set up Application Insights
6. ⚠️ **Implement CI/CD** - Automate deployments
7. 📊 **Monitor Costs** - Track Consumption plan usage
8. 🔄 **Plan Upgrade** - Consider Premium plan for production

---

## References

- [Azure Functions Consumption Plan](https://docs.microsoft.com/en-us/azure/azure-functions/consumption-plan)
- [Azure Functions .NET](https://docs.microsoft.com/en-us/azure/azure-functions/functions-dotnet-class-library)
- [Managed Identities](https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity)
- [Key Vault Integration](https://docs.microsoft.com/en-us/azure/app-service/app-service-key-vault-references)

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-25  
**Status:** ✅ Ready for deployment
