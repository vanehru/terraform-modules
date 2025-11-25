# Key Vault Module

This module creates an Azure Key Vault with private endpoint, network ACLs, access policies, and secret management.

## Features

- **Private Endpoint**: Secure access via private network
- **Network ACLs**: Deny by default with specific subnet/IP allowlist
- **Access Policies**: Fine-grained permissions for secrets, keys, and certificates
- **Secret Management**: Store and manage secrets with validation
- **Private DNS**: Automatic DNS zone creation and VNet linking
- **Soft Delete**: 90-day recovery period (Azure default)
- **Purge Protection**: Optional permanent deletion protection

## Usage

### Basic Configuration

```hcl
module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name              = "my-keyvault-${random_string.suffix.result}"
  location                    = "East US"
  resource_group_name         = "my-rg"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  
  # Network Security - Deny by default
  network_acls_default_action = "Deny"
  network_acls_bypass         = "AzureServices"
  allowed_subnet_ids          = [azurerm_subnet.app_subnet.id]
  allowed_ip_addresses        = [data.http.current_ip.response_body]
  
  # Access Policies
  access_policies = [
    {
      object_id          = azurerm_user_assigned_identity.app_identity.principal_id
      secret_permissions = ["Get", "List"]
    },
    {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
    }
  ]
  
  # Secrets (use kebab-case names)
  secrets = {
    "sql-connection-string" = "Server=..."
    "api-key"               = "secret-value"
  }
  
  # Private Endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.keyvault_subnet.id
  create_private_dns_zone    = true
  virtual_network_id         = azurerm_virtual_network.vnet.id
  
  tags = {
    environment = "production"
  }
}
```

### With Function App Integration

```hcl
module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name              = "my-keyvault-${random_string.suffix.result}"
  location                    = "East US"
  resource_group_name         = "my-rg"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  
  # Network Security
  network_acls_default_action = "Deny"
  network_acls_bypass         = "AzureServices"
  allowed_subnet_ids          = [
    azurerm_subnet.app_subnet.id,
    azurerm_subnet.keyvault_subnet.id
  ]
  allowed_ip_addresses        = [data.http.current_ip.response_body]
  
  # Access Policies - Least Privilege
  access_policies = [
    # Function App - Read-only access
    {
      object_id          = module.function_app.function_app_identity_principal_id
      secret_permissions = ["Get", "List"]
    },
    # Administrator - Full access
    {
      object_id          = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
      key_permissions    = ["Get", "List", "Create", "Delete", "Purge", "Recover"]
    }
  ]
  
  # Store application secrets
  secrets = {
    "sql-connection-string" = module.sql_database.connection_string
    "sql-username"          = module.sql_database.admin_username
    "sql-server-fqdn"       = module.sql_database.sql_server_fqdn
    "openai-endpoint"       = module.openai.openai_endpoint
    "openai-key"            = module.openai.openai_primary_key
  }
  
  # Private Endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.keyvault_subnet.id
  create_private_dns_zone    = true
  virtual_network_id         = azurerm_virtual_network.vnet.id
  
  depends_on = [
    module.sql_database,
    module.openai
  ]
}
```

## Network Security

### Network ACLs Configuration

The module enforces **deny by default** network access with explicit allowlists:

```hcl
network_acls {
  default_action             = "Deny"  # Block all by default
  bypass                     = "AzureServices"  # Allow trusted Microsoft services
  virtual_network_subnet_ids = [subnet1, subnet2]  # Allowed subnets
  ip_rules                   = ["1.2.3.4"]  # Allowed IP addresses
}
```

### Best Practices

1. **Always use "Deny" as default action** for production
2. **Allow specific subnets** where your applications run
3. **Add deployment IP** to allowed IPs for Terraform operations
4. **Use "AzureServices" bypass** to allow trusted Microsoft services
5. **Enable private endpoint** for VNet-only access

### Network Flow

```
Application (in VNet)
  ↓ Private Network
Private Endpoint (10.0.3.x)
  ↓ Private DNS Resolution
Key Vault (privatelink.vaultcore.azure.net)
  ↓ Network ACL Check
  ├─ Subnet in allowlist? → Allow
  ├─ IP in allowlist? → Allow
  └─ Default → Deny
```

## Access Policies

### Permission Levels

#### Read-Only (Application Access)
```hcl
{
  object_id          = app_identity_principal_id
  secret_permissions = ["Get", "List"]
}
```

#### Full Management (Administrator)
```hcl
{
  object_id          = admin_object_id
  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  key_permissions    = ["Get", "List", "Create", "Delete", "Purge", "Recover"]
  certificate_permissions = ["Get", "List", "Create", "Delete", "Purge", "Recover"]
}
```

#### Write Access (CI/CD Pipeline)
```hcl
{
  object_id          = pipeline_identity_principal_id
  secret_permissions = ["Get", "List", "Set"]
}
```

### Available Permissions

**Secret Permissions:**
- `Get` - Read secret value
- `List` - List secret names
- `Set` - Create/update secrets
- `Delete` - Soft delete secrets
- `Purge` - Permanently delete secrets
- `Recover` - Recover soft-deleted secrets
- `Backup` - Backup secrets
- `Restore` - Restore secrets

**Key Permissions:**
- Similar to secrets, plus cryptographic operations

**Certificate Permissions:**
- Similar to secrets, plus certificate-specific operations

### Least Privilege Principle

| Role | Get | List | Set | Delete | Purge | Recover |
|------|-----|------|-----|--------|-------|---------|
| **Application** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **CI/CD Pipeline** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Administrator** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## Secret Management

### Secret Naming Convention

**Required Format:** kebab-case (lowercase letters, numbers, hyphens)

✅ **Good Examples:**
- `sql-connection-string`
- `api-key`
- `storage-account-key`
- `openai-endpoint`
- `database-password`

❌ **Bad Examples:**
- `SQL_CONNECTION_STRING` (uppercase)
- `apiKey` (camelCase)
- `api.key` (dots not allowed)
- `api_key` (underscores not allowed)

### Secret Validation

The module validates secret names automatically:

```hcl
validation {
  condition = alltrue([
    for name in keys(var.secrets) : can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", name))
  ])
  error_message = "Secret names must use kebab-case format..."
}
```

### Storing Secrets

```hcl
secrets = {
  # Database credentials
  "sql-connection-string" = "Server=tcp:server.database.windows.net,1433;..."
  "sql-username"          = "sqladmin"
  "sql-password"          = random_password.sql_password.result
  
  # API keys
  "openai-key"            = azurerm_cognitive_account.openai.primary_access_key
  "storage-key"           = azurerm_storage_account.storage.primary_access_key
  
  # Endpoints
  "openai-endpoint"       = azurerm_cognitive_account.openai.endpoint
  "sql-server-fqdn"       = azurerm_mssql_server.sql.fully_qualified_domain_name
}
```

### Retrieving Secrets (Application Code)

#### C# / .NET
```csharp
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

var credential = new DefaultAzureCredential();
var client = new SecretClient(
    new Uri(Environment.GetEnvironmentVariable("KEY_VAULT_URI")),
    credential
);

KeyVaultSecret secret = await client.GetSecretAsync("sql-connection-string");
string connectionString = secret.Value;
```

#### Python
```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import os

credential = DefaultAzureCredential()
client = SecretClient(
    vault_url=os.environ["KEY_VAULT_URI"],
    credential=credential
)

secret = client.get_secret("sql-connection-string")
connection_string = secret.value
```

#### Node.js
```javascript
const { DefaultAzureCredential } = require("@azure/identity");
const { SecretClient } = require("@azure/keyvault-secrets");

const credential = new DefaultAzureCredential();
const client = new SecretClient(
    process.env.KEY_VAULT_URI,
    credential
);

const secret = await client.getSecret("sql-connection-string");
const connectionString = secret.value;
```

## Private Endpoint

### Configuration

```hcl
enable_private_endpoint    = true
private_endpoint_subnet_id = azurerm_subnet.keyvault_subnet.id
create_private_dns_zone    = true
virtual_network_id         = azurerm_virtual_network.vnet.id
```

### Private DNS Zone

The module automatically creates:
- **DNS Zone:** `privatelink.vaultcore.azure.net`
- **VNet Link:** Links DNS zone to your VNet
- **A Record:** Maps Key Vault name to private IP

### DNS Resolution

**From within VNet:**
```bash
nslookup my-keyvault.vault.azure.net
# Returns: 10.0.3.4 (private IP)
```

**From outside VNet:**
```bash
nslookup my-keyvault.vault.azure.net
# Returns: Public IP (but access denied by network ACLs)
```

## Security Features

### 1. Soft Delete (Enabled by Default)

- **Retention:** 90 days
- **Purpose:** Recover accidentally deleted secrets
- **Behavior:** Deleted secrets are soft-deleted, not permanently removed

```bash
# Recover a soft-deleted secret
az keyvault secret recover --vault-name my-keyvault --name my-secret
```

### 2. Purge Protection (Optional)

```hcl
purge_protection_enabled = true
```

- **Purpose:** Prevent permanent deletion during retention period
- **Use Case:** Compliance requirements (GDPR, HIPAA)
- **Warning:** Cannot be disabled once enabled

### 3. Encryption

- **At Rest:** All data encrypted with Microsoft-managed keys
- **In Transit:** TLS 1.2 minimum
- **Premium SKU:** HSM-backed keys available

### 4. Audit Logging

Enable diagnostic settings to track all access:

```hcl
resource "azurerm_monitor_diagnostic_setting" "kv_logs" {
  name                       = "key-vault-logs"
  target_resource_id         = module.key_vault.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  log {
    category = "AuditEvent"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| key_vault_name | Name of the Key Vault | string | - | yes |
| location | Azure region | string | - | yes |
| resource_group_name | Resource group name | string | - | yes |
| tenant_id | Azure AD tenant ID | string | - | yes |
| sku_name | SKU (standard or premium) | string | "standard" | no |
| purge_protection_enabled | Enable purge protection | bool | false | no |
| network_acls_default_action | Default action (Allow or Deny) | string | "Deny" | no |
| network_acls_bypass | Bypass setting | string | "AzureServices" | no |
| allowed_subnet_ids | Allowed subnet IDs | list(string) | [] | no |
| allowed_ip_addresses | Allowed IP addresses | list(string) | [] | no |
| access_policies | Access policies | list(object) | [] | no |
| enable_private_endpoint | Enable private endpoint | bool | true | no |
| private_endpoint_subnet_id | Private endpoint subnet ID | string | null | no |
| create_private_dns_zone | Create private DNS zone | bool | true | no |
| virtual_network_id | VNet ID for DNS link | string | null | no |
| secrets | Secrets to store | map(string) | {} | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| key_vault_id | Key Vault resource ID |
| key_vault_name | Key Vault name |
| key_vault_uri | Key Vault URI |
| private_endpoint_id | Private endpoint ID |
| private_endpoint_ip | Private endpoint IP address |
| secret_ids | Map of secret names to IDs |
| secret_names | List of secret names |
| access_policy_count | Number of access policies |
| network_acls_default_action | Network ACLs default action |

## Examples

### Development Environment

```hcl
module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name              = "dev-kv-${random_string.suffix.result}"
  location                    = "East US"
  resource_group_name         = "dev-rg"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false  # Allow purge in dev
  
  # More permissive network ACLs for dev
  network_acls_default_action = "Deny"
  network_acls_bypass         = "AzureServices"
  allowed_ip_addresses        = [data.http.current_ip.response_body]
  
  # Private endpoint optional for dev
  enable_private_endpoint    = false
}
```

### Production Environment

```hcl
module "key_vault" {
  source = "./modules/key-vault"

  key_vault_name              = "prod-kv-${random_string.suffix.result}"
  location                    = "East US"
  resource_group_name         = "prod-rg"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"  # HSM-backed keys
  purge_protection_enabled    = true  # Prevent accidental purge
  
  # Strict network ACLs
  network_acls_default_action = "Deny"
  network_acls_bypass         = "AzureServices"
  allowed_subnet_ids          = [
    azurerm_subnet.app_subnet.id,
    azurerm_subnet.keyvault_subnet.id
  ]
  
  # Private endpoint required
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.keyvault_subnet.id
  create_private_dns_zone    = true
  virtual_network_id         = azurerm_virtual_network.vnet.id
}
```

## Troubleshooting

### Cannot access Key Vault

**Symptoms:**
- 403 Forbidden errors
- "The client does not have permission" errors

**Solutions:**
1. Check access policy includes your identity
2. Verify network ACLs allow your subnet/IP
3. Check private endpoint is created and DNS resolves correctly
4. Verify managed identity is assigned to application

### DNS resolution fails

**Symptoms:**
- Key Vault resolves to public IP from within VNet
- Cannot connect to Key Vault from VNet

**Solutions:**
1. Verify private DNS zone is created
2. Check DNS zone is linked to VNet
3. Verify A record exists for Key Vault
4. Check private endpoint is in "Succeeded" state

### Secret name validation fails

**Symptoms:**
- Terraform validation error about secret names

**Solutions:**
1. Use kebab-case format (lowercase, hyphens only)
2. Avoid uppercase, underscores, dots
3. Examples: `sql-password`, `api-key`, `connection-string`

## Security Best Practices

### ✅ Do

1. **Use "Deny" as default action** for network ACLs
2. **Enable private endpoint** for production
3. **Use managed identities** for application access
4. **Grant least privilege** permissions (Get, List only for apps)
5. **Enable audit logging** to track all access
6. **Use kebab-case** for secret names
7. **Enable purge protection** for production
8. **Rotate secrets regularly** (manual or automated)

### ❌ Don't

1. **Don't use "Allow" as default** network action
2. **Don't grant excessive permissions** (Set, Delete, Purge to apps)
3. **Don't store secrets in code** or configuration files
4. **Don't use public access** for production workloads
5. **Don't share access keys** - use managed identities
6. **Don't disable soft delete** (it's enabled by default)

## Cost

### Standard SKU
- **Storage:** $0.03 per 10,000 transactions
- **Secrets:** No additional cost
- **Private Endpoint:** $4/month

### Premium SKU
- **Storage:** $0.03 per 10,000 transactions
- **HSM Operations:** $1 per 10,000 transactions
- **Private Endpoint:** $4/month

**Typical Monthly Cost:** $4-10 (mostly private endpoint)

## References

- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [Key Vault Best Practices](https://docs.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Managed Identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [Private Endpoints](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview)
