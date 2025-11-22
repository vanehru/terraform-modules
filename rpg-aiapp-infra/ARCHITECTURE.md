# RPG Gaming App - Detailed Architecture Documentation

## Table of Contents
1. [Overview](#overview)
2. [Network Architecture](#network-architecture)
3. [Security Architecture](#security-architecture)
4. [Component Details](#component-details)
5. [Data Flow Scenarios](#data-flow-scenarios)
6. [Deployment Guide](#deployment-guide)
7. [Operations Guide](#operations-guide)

---

## Overview

This document provides comprehensive details about the RPG Gaming App infrastructure deployed on Azure using Terraform. The architecture implements a fully isolated, secure backend with private endpoints and VNet integration.

### Design Principles

1. **Zero Trust Network Access**: No public internet access to backend services
2. **Defense in Depth**: Multiple security layers
3. **Least Privilege**: Minimal permissions for each component
4. **Infrastructure as Code**: Fully automated with Terraform
5. **Scalability**: Designed to handle growth
6. **High Availability**: Regional redundancy options

---

## Network Architecture

### Virtual Network Design

```
Azure Virtual Network: 10.0.0.0/16 (65,536 IP addresses)
│
├─ App Subnet: 10.0.1.0/24 (251 usable IPs)
│  ├─ Component: Static Web App (delegated)
│  ├─ Component: Function App (VNet integrated)
│  ├─ Service Endpoint: Microsoft.Web
│  ├─ Delegation: Microsoft.Web/serverFarms
│  └─ Purpose: Application tier (frontend + backend API)
│
├─ Storage Subnet: 10.0.2.0/24 (251 usable IPs)
│  ├─ Component: Storage Account Private Endpoint (10.0.2.x)
│  ├─ Service Endpoint: Microsoft.Storage
│  ├─ Private DNS: privatelink.blob.core.windows.net
│  └─ Purpose: Function App backend storage isolation
│
├─ Key Vault Subnet: 10.0.3.0/24 (251 usable IPs)
│  ├─ Component: Key Vault Private Endpoint (10.0.3.x)
│  ├─ Private DNS: privatelink.vaultcore.azure.net
│  └─ Purpose: Secret management tier
│
├─ Database Subnet: 10.0.4.0/24 (251 usable IPs)
│  ├─ Component: SQL Database Private Endpoint (10.0.4.x)
│  ├─ Service Endpoint: Microsoft.Sql
│  ├─ Private DNS: privatelink.database.windows.net
│  └─ Purpose: Data persistence tier
│
├─ OpenAI Subnet: 10.0.5.0/24 (251 usable IPs)
│  ├─ Component: Azure OpenAI Private Endpoint (10.0.5.x)
│  ├─ Private DNS: privatelink.openai.azure.com
│  └─ Purpose: AI/ML services tier
│
└─ Deployment Subnet: 10.0.6.0/24 (251 usable IPs)
   ├─ Component: Azure Cloud Shell Container Instance (10.0.6.x)
   ├─ Network Profile: cloudshell-network-profile
   ├─ Purpose: Secure deployment access to private endpoints
   └─ Cost: ~$5/month (vs ~$200/month for Bastion+VM)
```

### Subnet Design Rationale

**Why Dedicated Subnets per Component?**

1. **Security Isolation**: 
   - Each subnet can have its own NSG rules
   - Prevents lateral movement between services
   - Microsegmentation best practice

2. **Compliance**:
   - Meets PCI-DSS, HIPAA network segmentation requirements
   - Separate data tier from compute tier
   - Audit trail per subnet

3. **Traffic Control**:
   - Fine-grained control over which subnets can communicate
   - Easier to implement zero-trust networking
   - Service-specific firewall rules

4. **Scalability**:
   - Each subnet can grow to 251 IPs independently
   - Add more private endpoints per subnet if needed
   - No contention for IP space

5. **Operational Clarity**:
   - Clear separation of concerns
   - Easier troubleshooting (network issues isolated per tier)
   - Better monitoring and alerting

**Deployment Subnet Benefits:**
- **Cost Optimization**: Azure Cloud Shell is FREE, only Container Instance costs ~$5/month
- **Security**: No public jump box, access only through secure VNet relay
- **Convenience**: Pre-installed tools (Azure CLI, Functions Core Tools, git, npm, pip)
- **No Maintenance**: Microsoft manages updates, security patches
- **Persistent Storage**: 6 GB Cloud Shell storage for scripts and code

### Private DNS Architecture

Each private endpoint has an associated Private DNS Zone for name resolution within the VNet:

| Service | Private DNS Zone | Example FQDN |
|---------|-----------------|--------------|
| Key Vault | privatelink.vaultcore.azure.net | examplekv123.vault.azure.net |
| SQL Database | privatelink.database.windows.net | rpg-gaming-sql-server.database.windows.net |
| Azure OpenAI | privatelink.openai.azure.com | rpg-gaming-openai.openai.azure.com |
| Storage Account | privatelink.blob.core.windows.net | examplestoracc123.blob.core.windows.net |

**How it works:**
1. Service deployed with public FQDN (e.g., `examplekv123.vault.azure.net`)
2. Private endpoint created with private IP (e.g., `10.0.2.4`)
3. Private DNS zone overrides public DNS resolution
4. Within VNet, FQDN resolves to private IP
5. Outside VNet, FQDN resolves to public IP (but access is blocked)

### Network Security Groups (NSGs)

**Recommended NSG Rules:**

#### App Subnet NSG (10.0.1.0/24):
```
Inbound Rules:
Priority 100: Allow AzureLoadBalancer → Any (Port: Any)
Priority 110: Allow Internet → 443 (HTTPS for Static Web App)
Priority 120: Allow VirtualNetwork → VirtualNetwork
Priority 4096: Deny All

Outbound Rules:
Priority 100: Allow → 10.0.2.0/24 (Storage Subnet)
Priority 110: Allow → 10.0.3.0/24 (Key Vault Subnet)
Priority 120: Allow → 10.0.4.0/24 (Database Subnet)
Priority 130: Allow → 10.0.5.0/24 (OpenAI Subnet)
Priority 140: Allow → Internet (For outbound management)
Priority 4096: Deny All
```

#### Storage Subnet NSG (10.0.2.0/24):
```
Inbound Rules:
Priority 100: Allow 10.0.1.0/24 → 443 (From App Subnet)
Priority 4096: Deny All

Outbound Rules:
Priority 100: Allow → 10.0.1.0/24 (Response to App Subnet)
Priority 4096: Deny All
```

#### Key Vault Subnet NSG (10.0.3.0/24):
```
Inbound Rules:
Priority 100: Allow 10.0.1.0/24 → 443 (From App Subnet)
Priority 4096: Deny All

Outbound Rules:
Priority 100: Allow → 10.0.1.0/24 (Response to App Subnet)
Priority 4096: Deny All
```

#### Database Subnet NSG (10.0.4.0/24):
```
Inbound Rules:
Priority 100: Allow 10.0.1.0/24 → 1433 (SQL from App Subnet)
Priority 110: Allow 10.0.1.0/24 → 443 (Management)
Priority 4096: Deny All

Outbound Rules:
Priority 100: Allow → 10.0.1.0/24 (Response to App Subnet)
Priority 110: Allow → AzureMonitor (Diagnostics)
Priority 4096: Deny All
```

#### OpenAI Subnet NSG (10.0.5.0/24):
```
Inbound Rules:
Priority 100: Allow 10.0.1.0/24 → 443 (From App Subnet)
Priority 4096: Deny All

Outbound Rules:
Priority 100: Allow → 10.0.1.0/24 (Response to App Subnet)
Priority 4096: Deny All
```

---

## Security Architecture

### Authentication & Authorization Flow

```
┌──────────────┐
│     User     │
└──────┬───────┘
       │ 1. Anonymous Access
       ↓
┌──────────────────┐
│ Static Web App   │
│ (Public)         │
└──────┬───────────┘
       │ 2. Azure AD Auth (Optional)
       ↓
┌─────────────────────────────────────┐
│         Function App                │
│                                     │
│  Managed Identity:                  │
│  - Principal ID: xxxxxxxx           │
│  - Type: UserAssigned               │
└──────┬──────────────────────────────┘
       │ 3. Auth with Managed Identity
       ↓
┌─────────────────────────────────────┐
│         Key Vault                   │
│                                     │
│  Access Policy:                     │
│  - Object ID: <Function App MI>     │
│  - Permissions: Get, List (Secrets) │
└──────┬──────────────────────────────┘
       │ 4. Returns secrets
       ↓
┌──────────────────┐    ┌──────────────┐
│  SQL Database    │    │   OpenAI     │
│  (Private)       │    │  (Private)   │
└──────────────────┘    └──────────────┘
```

### Access Control Matrix

| Component | From | Authentication | Authorization | Network |
|-----------|------|----------------|---------------|---------|
| Static Web App | Internet | Optional AAD | Public | HTTPS |
| Function App | Static Web App | Azure Backbone | Linked API | Private |
| Key Vault | Function App | Managed Identity | RBAC + Access Policy | Private Endpoint |
| SQL Database | Function App | SQL Auth (from KV) | Database Roles | Private Endpoint |
| Azure OpenAI | Function App | API Key (from KV) | Subscription | Private Endpoint |
| Storage Account | Function App | Managed Identity | RBAC | Private Endpoint |

### Secret Management Strategy

**Secrets Lifecycle:**
```
1. Secret Generation:
   └─ Terraform generates random password
   └─ Password never displayed/logged

2. Secret Storage:
   └─ Terraform stores in Key Vault
   └─ Tagged with creation date

3. Secret Access:
   └─ Function App requests via Managed Identity
   └─ Key Vault validates identity
   └─ Audit log created

4. Secret Rotation (Manual):
   └─ Update Terraform variable
   └─ Apply changes
   └─ Key Vault updates secret
```

**Key Vault Secret Structure:**
```
examplekv123/
├─ secrets/
│  ├─ sql-connection-string (version 1, 2, 3...)
│  ├─ sql-username
│  ├─ sql-server-fqdn
│  ├─ sql-database-name
│  ├─ openai-endpoint
│  └─ openai-key
└─ access-policies/
   ├─ Function App (Get, List)
   └─ Admin (Full)
```

---

## Component Details

### 1. Static Web App

**Purpose**: Public-facing frontend for user registration and game interface

**Configuration:**
- SKU: Standard (supports custom domains, SLA, advanced features)
- Location: Follows resource group location
- Backend API: Linked to Function App

**Features:**
- Automatic HTTPS
- Global CDN distribution
- Built-in authentication (optional)
- Staging environments
- Custom domains

**Deployment Options:**
- GitHub Actions (CI/CD)
- Azure DevOps
- Manual upload

### 2. Function App

**Purpose**: Backend API for business logic, database operations, AI integration

**Configuration:**
- Runtime: Linux
- Plan: Premium V2 (P1v2) - Required for VNet integration
- Storage: Private endpoint enabled
- Identity: User-assigned managed identity
- VNet: Fully integrated with route-all-traffic enabled

**Key Settings:**
```
App Settings:
- WEBSITE_RUN_FROM_PACKAGE: "1" (deploy from package)
- KEY_VAULT_URI: https://examplekv123.vault.azure.net/
- SQL_CONNECTION_SECRET: sql-connection-string
- OPENAI_ENDPOINT_SECRET: openai-endpoint
- OPENAI_KEY_SECRET: openai-key
```

**Sample Function (Python):**
```python
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import pyodbc
import openai
import os

app = func.FunctionApp()

# Initialize Key Vault client
credential = DefaultAzureCredential()
kv_uri = os.environ["KEY_VAULT_URI"]
secret_client = SecretClient(vault_url=kv_uri, credential=credential)

@app.route(route="register", methods=["POST"])
def register_user(req: func.HttpRequest) -> func.HttpResponse:
    try:
        # Get secrets from Key Vault
        sql_conn = secret_client.get_secret("sql-connection-string").value
        openai_endpoint = secret_client.get_secret("openai-endpoint").value
        openai_key = secret_client.get_secret("openai-key").value
        
        # Parse request
        user_data = req.get_json()
        
        # Connect to SQL Database
        conn = pyodbc.connect(sql_conn)
        cursor = conn.cursor()
        
        # Insert user
        cursor.execute(
            "INSERT INTO Users (username, email, created_at) VALUES (?, ?, GETDATE())",
            user_data['username'], user_data['email']
        )
        conn.commit()
        
        # Generate personalized welcome message with OpenAI
        openai.api_base = openai_endpoint
        openai.api_key = openai_key
        
        response = openai.ChatCompletion.create(
            engine="gpt-35-turbo",
            messages=[{
                "role": "system",
                "content": "Create a personalized RPG welcome message"
            }, {
                "role": "user",
                "content": f"Welcome message for {user_data['username']}"
            }]
        )
        
        welcome_message = response.choices[0].message.content
        
        return func.HttpResponse(
            body=json.dumps({"message": welcome_message}),
            status_code=200
        )
    except Exception as e:
        return func.HttpResponse(f"Error: {str(e)}", status_code=500)
```

### 3. Azure SQL Database

**Purpose**: Primary data store for user information, game state, analytics

**Configuration:**
- Server Version: 12.0 (latest)
- Database SKU: General Purpose Serverless (GP_S_Gen5_2)
- Max Size: 32 GB
- TLS: 1.2 minimum
- Public Access: Disabled

**Private Connectivity:**
- Private Endpoint: Yes (10.0.2.x)
- VNet Rule: sql-subnet (10.0.3.0/24)
- Service Endpoint: Microsoft.Sql

**Sample Schema:**
```sql
-- Users Table
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(100) UNIQUE NOT NULL,
    Email NVARCHAR(255) UNIQUE NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    LastLogin DATETIME,
    IsActive BIT DEFAULT 1
);

-- GameSessions Table
CREATE TABLE GameSessions (
    SessionId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT FOREIGN KEY REFERENCES Users(UserId),
    StartTime DATETIME DEFAULT GETDATE(),
    EndTime DATETIME,
    Score INT,
    Level INT
);

-- AIInteractions Table
CREATE TABLE AIInteractions (
    InteractionId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT FOREIGN KEY REFERENCES Users(UserId),
    Prompt NVARCHAR(MAX),
    Response NVARCHAR(MAX),
    TokensUsed INT,
    Timestamp DATETIME DEFAULT GETDATE()
);

-- Create indexes for performance
CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_GameSessions_UserId ON GameSessions(UserId);
CREATE INDEX IX_AIInteractions_UserId ON AIInteractions(UserId);
```

### 4. Azure Key Vault

**Purpose**: Secure storage for secrets, keys, and certificates

**Configuration:**
- SKU: Standard
- Purge Protection: Disabled (for dev/test)
- Soft Delete: Enabled (90 days)
- Network ACLs: Deny by default
- Allowed Subnets: Function App, Endpoint subnet

**Access Policies:**
```
Function App Managed Identity:
- Secrets: Get, List

Administrator (Current User):
- Secrets: Get, List, Set, Delete, Purge, Recover
- Keys: All
- Certificates: All
```

**Monitoring:**
```
Diagnostic Settings:
- AuditEvent → Log Analytics
- AllMetrics → Log Analytics

Alerts:
- Failed access attempts > 5 in 5 minutes
- Secret accessed outside business hours
- New secret created
```

### 5. Azure OpenAI

**Purpose**: AI-powered game features (NPC dialogue, story generation, personalization)

**Configuration:**
- SKU: S0 (Standard)
- Location: East US (OpenAI availability)
- Public Access: Disabled
- Private Endpoint: Enabled

**Model Deployments:**
```
GPT-4:
- Model: gpt-4
- Version: 0613
- Scale: Standard
- Capacity: 10 tokens/min

GPT-3.5-Turbo:
- Model: gpt-35-turbo
- Version: 0613
- Scale: Standard
- Capacity: 20 tokens/min
```

**Use Cases:**
1. **Character Dialogue**: Generate NPC responses based on context
2. **Story Generation**: Create dynamic quest narratives
3. **Personalization**: Tailor game experience to player style
4. **Content Moderation**: Filter inappropriate user input

**Sample Usage:**
```python
import openai

# Configure from Key Vault
openai.api_base = "https://rpg-gaming-openai.openai.azure.com/"
openai.api_key = "<from-key-vault>"
openai.api_type = "azure"
openai.api_version = "2023-05-15"

# Generate NPC dialogue
response = openai.ChatCompletion.create(
    engine="gpt-4",
    messages=[
        {"role": "system", "content": "You are a wise wizard NPC in a fantasy RPG"},
        {"role": "user", "content": "The player asks about the ancient prophecy"}
    ],
    max_tokens=150,
    temperature=0.7
)

dialogue = response.choices[0].message.content
```

### 6. Storage Account

**Purpose**: Function App backend storage (code, logs, data)

**Configuration:**
- Tier: Standard
- Replication: LRS (Locally Redundant)
- Public Access: Disabled
- Network: Deny by default
- Private Endpoint: Enabled

**Containers:**
- `azure-webjobs-hosts`: Function runtime metadata
- `azure-webjobs-secrets`: Function keys
- `scm-releases`: Deployment packages

---

## Data Flow Scenarios

### Scenario 1: User Registration

```
Step 1: User submits registration form
  └─ Static Web App (HTTPS)
       └─ POST /api/register

Step 2: Function App receives request
  └─ Authenticates with Managed Identity
       └─ DefaultAzureCredential()

Step 3: Retrieve SQL credentials
  └─ Key Vault (Private Endpoint)
       └─ GET /secrets/sql-connection-string
       └─ Returns: Server=..;Database=..;

Step 4: Connect to database
  └─ SQL Database (Private Endpoint)
       └─ Connection via private IP (10.0.2.x)
       └─ INSERT INTO Users...

Step 5: Generate welcome message
  └─ Azure OpenAI (Private Endpoint)
       └─ POST /deployments/gpt-35-turbo/chat/completions
       └─ Returns AI-generated message

Step 6: Return response
  └─ Function App → Static Web App → User
       └─ HTTP 200 + Welcome message
```

### Scenario 2: Game Session Data

```
User plays game → Static Web App → Function App
                                      ↓
                              1. Get OpenAI key from Key Vault
                                      ↓
                              2. Query game state from SQL
                                      ↓
                              3. Generate AI content from OpenAI
                                      ↓
                              4. Update game state in SQL
                                      ↓
                              5. Return to user
```

### Scenario 3: Analytics Query

```
Admin Dashboard → Function App (Admin Auth)
                       ↓
                  Key Vault (Get SQL creds)
                       ↓
                  SQL Database (Complex queries)
                       ↓
                  Aggregate results
                       ↓
                  Return analytics data
```

---

## Deployment Guide

### Prerequisites

1. **Azure CLI** (2.50+)
2. **Terraform** (1.5+)
3. **Azure Subscription** with appropriate permissions
4. **Resource Provider** registrations:
   - Microsoft.Web
   - Microsoft.Sql
   - Microsoft.KeyVault
   - Microsoft.CognitiveServices
   - Microsoft.Storage
   - Microsoft.Network
   - Microsoft.ContainerInstance

### Step 1: Deploy Infrastructure

```bash
# 1. Login to Azure
az login
az account set --subscription "Your-Subscription-Name"

# 2. Navigate to project directory
cd rpg-aiapp-infra

# 3. Initialize Terraform
terraform init

# 4. Validate configuration
terraform validate

# 5. Plan deployment
terraform plan -out=deployment.tfplan

# 6. Review plan carefully (look for 6 subnets, 5 private endpoints)
terraform show deployment.tfplan

# 7. Apply configuration
terraform apply deployment.tfplan

# 8. Save outputs for later use
terraform output > deployment-info.txt
cat deployment-info.txt
```

### Step 2: Configure Azure Cloud Shell for VNet Access

#### Why Cloud Shell?

Azure Cloud Shell provides secure deployment access without expensive jump boxes:

| Feature | Cloud Shell + Container | Bastion + VM |
|---------|------------------------|--------------|
| Monthly Cost | **~$5** | ~$200 |
| Setup Time | 5 minutes | 20 minutes |
| Maintenance | None (Microsoft-managed) | OS patching, updates |
| Pre-installed Tools | Azure CLI, func, git, npm, pip | Manual installation |
| Security | VNet relay, no public IP | Public Bastion endpoint |

#### Configure Cloud Shell VNet Integration

```bash
# 1. Open Azure Cloud Shell (https://shell.azure.com)
# 2. Select Bash environment

# 3. Set variables from Terraform outputs
RG_NAME="example-rg"              # Your resource group name
VNET_NAME="example-vnet"          # Your VNet name
SUBNET_NAME="deployment-subnet"    # Deployment subnet (10.0.6.0/24)

# 4. Configure Cloud Shell to use Container Instance in VNet
az cloud-shell configure \
  --relay-resource-group $RG_NAME \
  --relay-vnet $VNET_NAME \
  --relay-subnet $SUBNET_NAME

# Cloud Shell will restart and connect to VNet
# This creates a Container Instance in your deployment subnet
# Takes ~2-3 minutes
```

#### Verify VNet Connectivity

```bash
# Test DNS resolution for private endpoints
nslookup examplekv123.vault.azure.net
# Should return private IP: 10.0.3.x

nslookup rpg-gaming-sql-server.database.windows.net
# Should return private IP: 10.0.4.x

nslookup rpg-gaming-openai.openai.azure.com
# Should return private IP: 10.0.5.x

# Test Key Vault access
az keyvault secret list --vault-name examplekv123

# Test Storage Account access
az storage account show --name <storage-account-name> --resource-group $RG_NAME
```

### Step 3: Deploy Application Code

#### Clone Your Repository

```bash
# Navigate to Cloud Shell home
cd ~

# Clone your application code
git clone https://github.com/your-org/rpg-gaming-app.git
cd rpg-gaming-app
```

#### Install Required Tools (if needed)

```bash
# Node.js (for Static Web App)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Azure Functions Core Tools
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Static Web Apps CLI
npm install -g @azure/static-web-apps-cli

# SQL Server command-line tools
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
sudo apt-get install -y mssql-tools unixodbc-dev

# Verify installations
func --version
swa --version
node --version
/opt/mssql-tools/bin/sqlcmd -?
```

#### Deploy Function App

```bash
cd ~/rpg-gaming-app/function-app

# Install Python dependencies
pip install -r requirements.txt

# Deploy to Azure Function App
func azure functionapp publish example-func --python

# Verify deployment
curl https://example-func.azurewebsites.net/api/health

# Stream logs
func azure functionapp logstream example-func
```

#### Deploy Static Web App

```bash
cd ~/rpg-gaming-app/frontend

# Install dependencies
npm install

# Build production bundle
npm run build

# Deploy using Static Web Apps CLI
swa deploy --app-name rpg-gaming-web --env production

# Or deploy using Azure CLI
az staticwebapp deploy \
  --name rpg-gaming-web \
  --app-location . \
  --output-location dist
```

### Step 4: Post-Deployment Verification

```bash
# 1. Test private endpoints connectivity
az network private-endpoint list \
  --resource-group example-rg \
  --query '[].{Name:name, ProvisioningState:provisioningState, Subnet:subnet.id}' \
  --output table

# 2. Verify Key Vault secrets are accessible
az keyvault secret show \
  --vault-name examplekv123 \
  --name sql-admin-password

# 3. Test SQL Database connectivity
/opt/mssql-tools/bin/sqlcmd \
  -S rpg-gaming-sql-server.database.windows.net \
  -d rpg-gaming-db \
  -U sqladmin \
  -P '<password-from-keyvault>' \
  -Q "SELECT @@VERSION"

# 4. Verify OpenAI deployments
az cognitiveservices account deployment list \
  --name rpg-gaming-openai \
  --resource-group example-rg \
  --output table

# 5. Test Function App endpoints
FUNC_URL=$(az functionapp show \
  --name example-func \
  --resource-group example-rg \
  --query defaultHostName -o tsv)

curl https://$FUNC_URL/api/health
curl -X POST https://$FUNC_URL/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com"}'

# 6. Get Static Web App URL
SWA_URL=$(az staticwebapp show \
  --name rpg-gaming-web \
  --resource-group example-rg \
  --query defaultHostname -o tsv)

echo "Static Web App: https://$SWA_URL"
```

### Deployment Best Practices

#### Create Deployment Script

Save time with a reusable deployment script:

```bash
cat > ~/deploy-rpg-app.sh <<'EOF'
#!/bin/bash
set -e

echo "🚀 RPG Gaming App Deployment"
echo "=============================="

# Variables
RG_NAME="example-rg"
FUNC_NAME="example-func"
SWA_NAME="rpg-gaming-web"

# Function App
echo "📦 Deploying Function App..."
cd ~/rpg-gaming-app/function-app
func azure functionapp publish $FUNC_NAME --python

# Static Web App
echo "🌐 Deploying Static Web App..."
cd ~/rpg-gaming-app/frontend
npm run build
swa deploy --app-name $SWA_NAME --env production

# Verification
echo "✅ Deployment Complete!"
echo ""
echo "URLs:"
FUNC_URL=$(az functionapp show --name $FUNC_NAME --resource-group $RG_NAME --query defaultHostName -o tsv)
SWA_URL=$(az staticwebapp show --name $SWA_NAME --resource-group $RG_NAME --query defaultHostname -o tsv)
echo "  Function App: https://$FUNC_URL"
echo "  Static Web App: https://$SWA_URL"
EOF

chmod +x ~/deploy-rpg-app.sh

# Run deployment
~/deploy-rpg-app.sh
```

#### Use tmux for Persistent Sessions

Cloud Shell has 20-minute idle timeout. Use tmux to maintain sessions:

```bash
# Install tmux
sudo apt-get update && sudo apt-get install -y tmux

# Create named session
tmux new -s deployment

# Work in session...

# Detach with: Ctrl+b, then d
# Reattach later with:
tmux attach -t deployment

# List sessions:
tmux ls
```

### Troubleshooting Deployment

#### Cloud Shell Can't Access Private Endpoints

```bash
# Check container status
az container show \
  --name cloudshell-relay \
  --resource-group example-rg \
  --query provisioningState

# Restart container if needed
az container restart \
  --name cloudshell-relay \
  --resource-group example-rg

# Verify network profile
az network profile show \
  --name cloudshell-network-profile \
  --resource-group example-rg

# Re-configure Cloud Shell
az cloud-shell configure \
  --relay-resource-group example-rg \
  --relay-vnet example-vnet \
  --relay-subnet deployment-subnet
```

#### DNS Resolution Failing

```bash
# Check private DNS zones
az network private-dns zone list \
  --resource-group example-rg \
  --output table

# Verify VNet links
az network private-dns link vnet list \
  --resource-group example-rg \
  --zone-name privatelink.vaultcore.azure.net

# Test with dig
dig examplekv123.vault.azure.net

# Should show A record pointing to 10.0.3.x
```

#### Function App Deployment Fails

```bash
# Check Function App status
az functionapp show \
  --name example-func \
  --resource-group example-rg \
  --query state

# Restart Function App
az functionapp restart \
  --name example-func \
  --resource-group example-rg

# Check deployment logs
func azure functionapp logstream example-func

# Verify VNet integration
az functionapp vnet-integration list \
  --name example-func \
  --resource-group example-rg
```

---

## Operations Guide

### Monitoring

**Application Insights:**
```bash
# Enable for Function App
az monitor app-insights component create \
  --app example-func-insights \
  --location eastus \
  --resource-group example-rg \
  --application-type web

# Link to Function App
az functionapp config appsettings set \
  --name example-func \
  --resource-group example-rg \
  --settings "APPINSIGHTS_INSTRUMENTATIONKEY=<key>"
```

**Log Analytics Queries:**
```kusto
// Failed Key Vault access
AzureDiagnostics
| where ResourceType == "VAULTS"
| where ResultSignature == "Forbidden"
| project TimeGenerated, CallerIPAddress, Resource, OperationName

// Function execution errors
traces
| where severityLevel >= 3
| project timestamp, message, severityLevel

// SQL performance
AzureDiagnostics
| where ResourceType == "SERVERS/DATABASES"
| where Category == "SQLInsights"
| summarize avg(dtu_consumption_percent) by bin(TimeGenerated, 5m)
```

### Backup & Recovery

**SQL Database:**
```bash
# Automated backups are enabled by default (7-35 days retention)
# Manual backup
az sql db export \
  --server rpg-gaming-sql-server \
  --database rpg-gaming-db \
  --storage-key-type StorageAccessKey \
  --storage-key <key> \
  --storage-uri https://backupstorage.blob.core.windows.net/backups/db-backup.bacpac
```

**Key Vault:**
```bash
# Backup secrets
az keyvault secret backup \
  --vault-name examplekv123 \
  --name sql-connection-string \
  --file sql-connection-string.backup
```

### Disaster Recovery

**Recovery Time Objective (RTO):** 1 hour  
**Recovery Point Objective (RPO):** 5 minutes

**DR Steps:**
1. Terraform state backup (automated)
2. SQL database geo-replication (optional, for production)
3. Key Vault soft-delete enabled (90-day recovery)
4. Function App deployment slots (blue-green deployment)

---

## Appendix

### Terraform Module Dependencies

```
main.tf
  ├─ module.function_app
  │    └─ Depends on: VNet, Subnets
  ├─ module.key_vault
  │    └─ Depends on: function_app (for managed identity)
  │    └─ Depends on: sql_database, openai (for secrets)
  ├─ module.sql_database
  │    └─ Depends on: VNet, Subnets
  ├─ module.openai
  │    └─ Depends on: VNet, Subnets
  └─ module.static_web_app
       └─ Depends on: function_app (for linking)
```

### Cost Estimation (Monthly)

| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| Function App (Premium V2) | P1v2 | $146.00 |
| Static Web App | Standard | $9.00 |
| SQL Database | GP_S_Gen5_2 | $120.00 |
| Azure OpenAI | S0 (with usage) | $50-200.00 |
| Storage Account | Standard LRS | $1.00 |
| Key Vault | Standard | $0.03 |
| Private Endpoints (4x) | $4 each | $16.00 |
| VNet | Standard | $0.00 |
| **Total** | | **~$342-$492/month** |

*Prices are estimates and vary by region. OpenAI costs depend heavily on usage.*

### Resource Naming Conventions

```
Pattern: {project}-{environment}-{resource-type}-{instance}

Examples:
- rpg-prod-func-01
- rpg-dev-sql-01
- rpg-test-kv-01
- rpg-prod-openai-01
```

### Tags Strategy

```hcl
tags = {
  Environment     = "Development|Staging|Production"
  Project         = "RPG-Gaming-App"
  CostCenter      = "Engineering"
  Owner           = "Platform-Team"
  ManagedBy       = "Terraform"
  SecurityLevel   = "High"
  DataClass       = "Confidential"
}
```

---

**Document Version:** 1.0  
**Last Updated:** November 22, 2025  
**Maintained By:** Platform Engineering Team
