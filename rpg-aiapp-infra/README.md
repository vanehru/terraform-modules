# RPG Gaming App Infrastructure

This Terraform configuration sets up a complete Azure infrastructure for an RPG gaming application with full private endpoint connectivity and network isolation.

## Architecture Overview

### High-Level Architecture Diagram

```
                          Internet
                             ↓
                    ┌─────────────────┐
                    │ Static Web App  │ (Public - User Registration)
                    │   (Frontend)    │
                    └─────────────────┘
                             ↓ (Linked Backend API)
                             ↓
              ╔══════════════════════════════╗
              ║   Azure Virtual Network      ║
              ║      (10.0.0.0/16)          ║
              ║                              ║
              ║  ┌────────────────────────┐ ║
              ║  │   App Subnet           │ ║
              ║  │     (10.0.1.0/24)      │ ║
              ║  │  ┌──────────────────┐  │ ║
              ║  │  │  Static Web App  │  │ ║
              ║  │  │  (Delegated)     │  │ ║
              ║  │  └──────────────────┘  │ ║
              ║  │  ┌──────────────────┐  │ ║
              ║  │  │  Function App    │  │ ║
              ║  │  │ (VNet Integrated)│  │ ║
              ║  │  └──────────────────┘  │ ║
              ║  └────────────────────────┘ ║
              ║              ↓               ║
              ║  ┌────────────────────────┐ ║
              ║  │  Storage Subnet        │ ║
              ║  │     (10.0.2.0/24)      │ ║
              ║  │  ┌──────────────────┐  │ ║
              ║  │  │ Storage Account  │  │ ║
              ║  │  │ (Private Endpoint)│  │ ║
              ║  │  └──────────────────┘  │ ║
              ║  └────────────────────────┘ ║
              ║              ↓               ║
              ║  ┌────────────────────────┐ ║
              ║  │  Key Vault Subnet      │ ║
              ║  │     (10.0.3.0/24)      │ ║
              ║  │  ┌──────────────────┐  │ ║
              ║  │  │   Key Vault      │  │ ║
              ║  │  │ (Private Endpoint)│  │ ║
              ║  │  └──────────────────┘  │ ║
              ║  └────────────────────────┘ ║
              ║              ↓               ║
              ║  ┌────────────────────────┐ ║
              ║  │  Database Subnet       │ ║
              ║  │     (10.0.4.0/24)      │ ║
              ║  │  ┌──────────────────┐  │ ║
              ║  │  │  SQL Database    │  │ ║
              ║  │  │ (Private Endpoint)│  │ ║
              ║  │  └──────────────────┘  │ ║
              ║  └────────────────────────┘ ║
              ║              ↓               ║
              ║  ┌────────────────────────┐ ║
              ║  │  OpenAI Subnet         │ ║
              ║  │     (10.0.5.0/24)      │ ║
              ║  │  ┌──────────────────┐  │ ║
              ║  │  │    OpenAI        │  │ ║
              ║  │  │ (Private Endpoint)│  │ ║
              ║  │  └──────────────────┘  │ ║
              ║  └────────────────────────┘ ║
              ║                              ║
              ╚══════════════════════════════╝
```

## Security Architecture

### Private Endpoint Configuration

| Service | Private Endpoint | Public Access | Network Isolation |
|---------|-----------------|---------------|-------------------|
| **Key Vault** | ✅ Enabled | ❌ Denied (Network ACLs) | VNet only |
| **SQL Database** | ✅ Enabled | ❌ Disabled | VNet only |
| **Azure OpenAI** | ✅ Enabled | ❌ Disabled | VNet only |
| **Storage Account** | ✅ Enabled | ❌ Disabled | VNet only |
| **Function App** | VNet Integrated | ⚠️ Managed by Azure | Routes all traffic through VNet |
| **Static Web App** | N/A* | ✅ Public | Internet-facing (Frontend) |

\* *Static Web Apps are designed to be public-facing frontends and don't support private endpoints*

### Private DNS Zones

All private endpoints use Private DNS Zones for name resolution within the VNet:

- **Key Vault**: `privatelink.vaultcore.azure.net`
- **SQL Database**: `privatelink.database.windows.net`
- **Azure OpenAI**: `privatelink.openai.azure.com`
- **Storage Account**: `privatelink.blob.core.windows.net`

### Components

1. **Static Web App** - Frontend for user registration and game interface (Public)
2. **Function App** - Backend API triggered by user actions (VNet Integrated)
3. **SQL Database** - Stores user data and game state (Private Endpoint)
4. **Key Vault** - Securely stores database credentials and API keys (Private Endpoint)
5. **Azure OpenAI** - AI-powered game features and interactions (Private Endpoint)
6. **Storage Account** - Function App backend storage (Private Endpoint)
7. **Virtual Network** - Complete network isolation with private endpoints

### Network Security Features

#### 1. **Complete Private Endpoint Coverage**
   - All backend services (SQL, Key Vault, OpenAI, Storage) use private endpoints
   - No public internet access to backend resources
   - All traffic flows through the private VNet

#### 2. **VNet Integration**
   - Function App is integrated with VNet (`vnet_route_all_enabled = true`)
   - All outbound traffic from Function App routed through VNet
   - Access to private endpoint services without public IPs

#### 3. **Network Access Control Lists (ACLs)**
   - **Key Vault**: Default action = Deny, only specific subnets allowed
   - **Storage Account**: Default action = Deny, only specific subnets allowed
   - **SQL Database**: Public network access disabled
   - **OpenAI**: Public network access disabled

#### 4. **Service Endpoints**
   - **Microsoft.Web** on Function App subnet (10.0.1.0/24)
   - **Microsoft.Sql** on SQL subnet (10.0.3.0/24)

#### 5. **Managed Identity & Zero Secrets**
   - Function App uses Managed Identity to access Key Vault
   - No passwords or keys stored in application code
   - All secrets retrieved from Key Vault at runtime

## Data Flow

### User Registration Flow (Detailed)

```
┌─────────┐
│  User   │
└────┬────┘
     │ 1. Registers on website
     ↓
┌─────────────────┐
│ Static Web App  │ (Public, Internet-facing)
└────┬────────────┘
     │ 2. Calls backend API
     ↓
┌─────────────────────────────────────────┐
│       Function App                      │
│  (VNet Integrated - Private Network)    │
│                                         │
│  3. Uses Managed Identity               │
│     to authenticate                     │
└────┬────────────────────────────────────┘
     │ 4. Retrieves secrets via private endpoint
     ↓
┌─────────────────┐
│   Key Vault     │ (Private Endpoint)
│                 │
│  Returns:       │
│  - SQL conn str │
│  - OpenAI key   │
└────┬────────────┘
     │ 5. Connects via private endpoint
     ↓
┌─────────────────┐
│  SQL Database   │ (Private Endpoint)
│                 │
│  6. Stores user │
│     information │
└────┬────────────┘
     │
     │ 7. Generate personalized content
     ↓
┌─────────────────┐
│  Azure OpenAI   │ (Private Endpoint)
│                 │
│  8. AI-powered  │
│     game content│
└─────────────────┘
     │
     │ 9. Response flows back
     ↓
    User
```

### Traffic Flow Summary

```
User → Static Web App → Function App (VNet) → Private Network
                           ↓
              ┌────────────┼────────────┐
              ↓            ↓            ↓
         Key Vault    SQL Database   OpenAI
         (Private)     (Private)    (Private)
              ↓
      Storage Account
         (Private)
```

**All backend communication happens through private endpoints - zero public internet exposure!**

## Modules

### Function App Module (`modules/function-app/`)
- Azure Function App (Linux)
- App Service Plan
- Storage Account with Private Endpoint
- Managed Identity
- VNet Integration
- Private DNS Zone for Storage

### Key Vault Module (`modules/key-vault/`)
- Azure Key Vault
- Private Endpoint
- Private DNS Zone
- Access Policies
- Secret Management

### SQL Database Module (`modules/sql-database/`)
- Azure SQL Server
- SQL Database
- Private Endpoint
- Firewall Rules
- VNet Rules

### OpenAI Module (`modules/openai/`)
- Azure OpenAI Service
- Model Deployments (GPT-4, GPT-3.5-turbo)
- Private Endpoint
- Private DNS Zone

### Static Web App Module (`modules/static-web-app/`)
- Azure Static Web App
- Function App Integration
- Custom Domain Support

## Configuration

### Key Settings

**Function App Environment Variables:**
- `KEY_VAULT_URI` - Key Vault endpoint
- `SQL_CONNECTION_SECRET` - Name of secret containing SQL connection string
- `OPENAI_ENDPOINT_SECRET` - Name of secret containing OpenAI endpoint
- `OPENAI_KEY_SECRET` - Name of secret containing OpenAI API key

**Secrets Stored in Key Vault:**
- `sql-connection-string` - Full SQL connection string (including password)
- `sql-username` - SQL admin username
- `sql-server-fqdn` - SQL server FQDN (private endpoint address)
- `sql-database-name` - Database name
- `openai-endpoint` - OpenAI service endpoint (private endpoint address)
- `openai-key` - OpenAI API key (primary access key)

### Security Best Practices Implemented

1. ✅ **Zero Trust Network Access**
   - All backend services deny public access by default
   - Access only through VNet with private endpoints

2. ✅ **Defense in Depth**
   - Multiple layers: VNet, Private Endpoints, Network ACLs, Managed Identity
   - No single point of failure

3. ✅ **Least Privilege Access**
   - Function App can only read secrets (Get, List)
   - Admin has full management permissions
   - SQL access restricted to specific subnets

4. ✅ **Secret Management**
   - All credentials stored in Key Vault
   - Auto-generated strong passwords (16 characters)
   - No secrets in code or configuration files

5. ✅ **Network Segmentation**
   - Separate subnets for different workload types
   - Service endpoints for additional security
   - Private DNS for internal name resolution

6. ✅ **Encryption in Transit**
   - TLS 1.2 minimum for SQL Server
   - HTTPS enforced for all communications
   - Private backbone for inter-service communication

## Network Configuration

### Subnet Architecture

The infrastructure uses a **dedicated subnet per component** approach for better security isolation and management:

#### Subnet Layout

```
Virtual Network: 10.0.0.0/16 (65,536 IPs)
│
├─ 1. App Subnet (10.0.1.0/24) - 251 IPs
│  ├─ Purpose: Application tier (Frontend + Backend)
│  ├─ Components: Static Web App (delegated), Function App (VNet integrated)
│  ├─ Service Endpoints: Microsoft.Web
│  ├─ Delegation: Microsoft.Web/serverFarms
│  └─ Outbound: Routes to all other subnets via private network
│
├─ 2. Storage Subnet (10.0.2.0/24) - 251 IPs
│  ├─ Purpose: Storage tier (Function App backend storage)
│  ├─ Components: Storage Account (Private Endpoint)
│  ├─ Service Endpoints: Microsoft.Storage
│  ├─ Private DNS: privatelink.blob.core.windows.net
│  └─ Access: Only from App subnet
│
├─ 3. Key Vault Subnet (10.0.3.0/24) - 251 IPs
│  ├─ Purpose: Secret management tier
│  ├─ Components: Key Vault (Private Endpoint)
│  ├─ Private DNS: privatelink.vaultcore.azure.net
│  ├─ Network ACLs: Deny by default
│  └─ Access: Only from App subnet
│
├─ 4. Database Subnet (10.0.4.0/24) - 251 IPs
│  ├─ Purpose: Data tier (SQL Database)
│  ├─ Components: SQL Database (Private Endpoint)
│  ├─ Service Endpoints: Microsoft.Sql
│  ├─ Private DNS: privatelink.database.windows.net
│  ├─ Public Access: Disabled
│  └─ Access: Only from App subnet via private endpoint
│
└─ 5. OpenAI Subnet (10.0.5.0/24) - 251 IPs
   ├─ Purpose: AI/ML tier
   ├─ Components: Azure OpenAI (Private Endpoint)
   ├─ Private DNS: privatelink.openai.azure.com
   ├─ Public Access: Disabled
   └─ Access: Only from App subnet
```

### Subnet Design Benefits

1. **Security Isolation**: Each component in its own subnet
2. **Network Segmentation**: Easier to apply NSGs per tier
3. **Traffic Control**: Fine-grained control over inter-subnet communication
4. **Compliance**: Meets security frameworks requiring network segmentation
5. **Scalability**: Each subnet can grow independently (251 IPs each)
6. **Troubleshooting**: Easier to diagnose network issues per component

### Traffic Flow Matrix

| From / To | App Subnet | Storage | Key Vault | Database | OpenAI |
|-----------|------------|---------|-----------|----------|--------|
| **App Subnet** | ✅ Local | ✅ Private | ✅ Private | ✅ Private | ✅ Private |
| **Storage** | ✅ Response | ❌ N/A | ❌ Deny | ❌ Deny | ❌ Deny |
| **Key Vault** | ✅ Response | ❌ Deny | ❌ N/A | ❌ Deny | ❌ Deny |
| **Database** | ✅ Response | ❌ Deny | ❌ Deny | ❌ N/A | ❌ Deny |
| **OpenAI** | ✅ Response | ❌ Deny | ❌ Deny | ❌ Deny | ❌ N/A |

**Key Points:**
- ✅ Only App Subnet can initiate connections to backend services
- ✅ Backend services can only respond (stateful firewall)
- ❌ No lateral movement between backend subnets
- ❌ No direct internet access from backend subnets

### Network Flow Rules

#### 1. **Inbound Traffic**:
   - Internet → Static Web App (Public, via Azure CDN)
   - Static Web App → Function App (via Azure backbone, linked API)
   - Function App → Private Endpoints (via VNet, each in dedicated subnet)

#### 2. **Outbound Traffic**:
   - Function App → All traffic routed through VNet (`vnet_route_all_enabled = true`)
   - App Subnet (10.0.1.0/24) → Storage Subnet (10.0.2.0/24)
   - App Subnet (10.0.1.0/24) → Key Vault Subnet (10.0.3.0/24)
   - App Subnet (10.0.1.0/24) → Database Subnet (10.0.4.0/24)
   - App Subnet (10.0.1.0/24) → OpenAI Subnet (10.0.5.0/24)

#### 3. **Blocked Traffic**:
   - Internet → Storage Account ❌ (Private endpoint only)
   - Internet → Key Vault ❌ (Network ACLs deny)
   - Internet → SQL Database ❌ (Public access disabled)
   - Internet → OpenAI ❌ (Public access disabled)
   - Storage ↔ Key Vault ❌ (No lateral movement)
   - Storage ↔ Database ❌ (No lateral movement)
   - Database ↔ OpenAI ❌ (No lateral movement)

### Service Endpoints

Service endpoints provide optimized routing from subnets to Azure services:

- **App Subnet (10.0.1.0/24)**: Microsoft.Web
- **Storage Subnet (10.0.2.0/24)**: Microsoft.Storage
- **Database Subnet (10.0.4.0/24)**: Microsoft.Sql

### Subnet Delegation

**App Subnet** is delegated to `Microsoft.Web/serverFarms` which allows:
- Function App to use regional VNet integration
- Static Web App backend integration (if needed)
- Automatic NSG rule management for App Service

## Deployment

### Prerequisites
- Azure CLI installed and authenticated
- Terraform >= 1.0
- Appropriate Azure permissions

### Steps

1. Initialize Terraform:
```bash
terraform init
```

2. Review the plan:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

## Usage

### Accessing Services

- **Static Web App URL**: Available in `module.static_web_app.default_host_name`
- **Function App URL**: Available in `module.function_app.function_app_default_hostname`

### Function App Code Example

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import pyodbc
import openai

# Get Key Vault URI from environment
key_vault_uri = os.environ["KEY_VAULT_URI"]
credential = DefaultAzureCredential()
secret_client = SecretClient(vault_url=key_vault_uri, credential=credential)

# Get SQL connection string from Key Vault
sql_connection = secret_client.get_secret("sql-connection-string").value

# Get OpenAI credentials from Key Vault
openai_endpoint = secret_client.get_secret("openai-endpoint").value
openai_key = secret_client.get_secret("openai-key").value

# Connect to SQL Database
conn = pyodbc.connect(sql_connection)
cursor = conn.cursor()

# Use OpenAI for game content
openai.api_key = openai_key
openai.api_base = openai_endpoint
```

## Customization

### Modifying OpenAI Models

Edit the `deployments` map in `main.tf`:

```hcl
deployments = {
  "gpt-4" = {
    model_name    = "gpt-4"
    model_version = "0613"
    scale_type    = "Standard"
    capacity      = 10
  }
}
```

### Changing SQL Database SKU

Modify the `sku_name` parameter:

```hcl
sku_name = "S0"  # Basic tier
# or
sku_name = "GP_Gen5_2"  # General Purpose
```

## Cost Optimization

- Use consumption plan for Function App (Y1) for development
- Use Basic tier for SQL Database during testing
- Adjust OpenAI deployment capacity based on usage

## Troubleshooting

### Function App Cannot Access Key Vault
1. Verify managed identity is enabled on Function App
2. Check Key Vault access policies include Function App's managed identity principal ID
3. Ensure Function App subnet (10.0.1.0/24) is in Key Vault's allowed subnets
4. Verify VNet integration is properly configured
5. Check that `vnet_route_all_enabled = true` is set

### SQL Connection Fails
1. Verify Function App subnet has Microsoft.Sql service endpoint enabled
2. Check SQL firewall allows Azure services (or specific VNet rules)
3. Ensure SQL connection string in Key Vault is correct
4. Verify SQL private endpoint is created and healthy
5. Check private DNS zone is linked to VNet
6. Confirm `public_network_access_enabled = false` is working correctly

### Cannot Access Storage Account
1. Check storage account private endpoint is deployed
2. Verify storage account network rules allow Function App subnet
3. Ensure private DNS zone for blob storage is configured
4. Check that storage account has `public_network_access_enabled = false`

### OpenAI Service Not Responding
1. Verify OpenAI private endpoint is created
2. Check OpenAI endpoint URL in Key Vault matches private endpoint
3. Ensure Function App can resolve private DNS for OpenAI
4. Verify API key is correct in Key Vault
5. Check model deployments are active

### DNS Resolution Issues
1. Verify all private DNS zones are created:
   - privatelink.vaultcore.azure.net
   - privatelink.database.windows.net
   - privatelink.openai.azure.com
   - privatelink.blob.core.windows.net
2. Check DNS zones are linked to the VNet
3. Verify A records point to correct private IP addresses

## Monitoring and Diagnostics

### Key Metrics to Monitor
- **Function App**: Execution count, errors, response time
- **Key Vault**: Access attempts, denied requests
- **SQL Database**: DTU/CPU usage, connections, deadlocks
- **OpenAI**: Token usage, request latency, throttling
- **Storage Account**: Transaction count, availability

### Diagnostic Settings
Enable diagnostic logs for:
- Function App → Log Analytics
- Key Vault → Log Analytics (audit all access)
- SQL Database → Log Analytics (query performance)
- VNet → Network Watcher (connection monitoring)

## Cost Optimization Tips

### Development Environment
- Function App: Use Consumption Plan (Y1) instead of Premium (P1v2)
- SQL Database: Use Basic tier (DTU-based) or Serverless
- OpenAI: Start with lower capacity (5-10 tokens/min)
- Storage Account: Use Standard tier with LRS replication

### Production Environment
- Function App: Premium V2 for VNet integration (current config)
- SQL Database: General Purpose with appropriate DTUs
- OpenAI: Scale capacity based on usage patterns
- Enable auto-scaling where possible

### Cost Monitoring
```bash
# Estimate monthly costs
terraform plan -out=plan.out
terraform show -json plan.out | jq '.resource_changes[].change.after.sku_name'
```

## License

MIT License
