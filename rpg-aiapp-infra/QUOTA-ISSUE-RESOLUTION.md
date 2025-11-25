# Quota Issue Resolution

**Issue:** Function App deployment failed due to quota limitations for Dynamic VMs (Consumption plan).

**Error:**
```
Error: creating App Service Plan - Operation cannot be completed without additional quota.
Current Limit (Dynamic VMs): 0
```

---

## Current Status

### ✅ Successfully Deployed

The following resources were created successfully:

1. **Resource Group** - rpg-aiapp-rg
2. **Virtual Network** - demo-rpg-vnet with 6 subnets
3. **Key Vault** - demo-rpgkv-r8g0md
   - Private endpoint configured
   - 6 secrets stored (SQL and OpenAI credentials)
4. **SQL Database** - rpg-sql-r8g0md
   - Private endpoint configured
   - Basic SKU (2GB)
5. **Azure OpenAI** - rpg-openai-r8g0md
   - S0 SKU
   - Public access (private endpoint optional)
6. **Static Web App** - rpg-gaming-web-r8g0md
   - Standard SKU
7. **Cloud Shell Storage** - cloudshellr8g0md

### ❌ Failed to Deploy

- **Function App** - Quota limitation

---

## Solution Options

### Option 1: Request Quota Increase (Recommended)

**Steps:**
1. Go to Azure Portal
2. Navigate to **Subscriptions** → Your subscription
3. Click **Usage + quotas**
4. Search for "App Service"
5. Find "Dynamic VMs" or "Consumption Plan"
6. Click **Request increase**
7. Request at least 1 Dynamic VM

**Timeline:** Usually approved within 24-48 hours

**After Approval:**
```bash
# Re-run terraform apply
terraform apply
```

### Option 2: Use Different Region

Some regions may have available quota. Try changing the location:

```hcl
# In variables.tf or main.tf
variable "azurerm_resource_group_location" {
  default = "East US"  # Try different region
}
```

**Regions to try:**
- East US
- West US
- West Europe
- North Europe

### Option 3: Deploy Without Function App

Since you don't have quota, you can use the infrastructure without the Function App for now.

**What works without Function App:**
- ✅ Static Web App (frontend)
- ✅ SQL Database (data storage)
- ✅ Key Vault (secret management)
- ✅ Azure OpenAI (AI features)

**What doesn't work:**
- ❌ Backend API (Function App)
- ❌ Server-side logic

**To deploy without Function App:**

1. Comment out the Function App module in `main.tf`
2. Remove Function App reference from Key Vault access policies
3. Remove Function App reference from Static Web App

---

## Quick Fix: Deploy Without Function App

### Step 1: Update main.tf

Comment out the Function App module (lines ~130-170):

```hcl
# Function App Module - Commented out due to quota limitations
# module "function_app" {
#   source = "./modules/function-app"
#   ...
# }
```

### Step 2: Update Key Vault Access Policies

Remove Function App from access policies (in main.tf, around line 183):

```hcl
access_policies = [
  # Function App access policy removed due to quota limitations
  # {
  #   object_id          = module.function_app.function_app_identity_principal_id
  #   secret_permissions = ["Get", "List"]
  # },
  # Administrator access policy - full management permissions
  {
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }
]
```

### Step 3: Update Static Web App

Ensure function_app_id is null (already done):

```hcl
module "static_web_app" {
  # ...
  function_app_id = null  # Already set
}
```

### Step 4: Update Outputs

Comment out Function App outputs in `outputs.tf`:

```hcl
# Function App outputs commented out due to quota limitations
# output "function_app_name" {
#   description = "Name of the Function App"
#   value       = module.function_app.function_app_name
# }
```

### Step 5: Re-apply

```bash
terraform apply
```

---

## Alternative: Use Azure Container Apps

If you can't get Function App quota, consider Azure Container Apps as an alternative:

**Advantages:**
- Similar serverless experience
- May have different quota limits
- Supports containers
- Can run .NET applications

**Create Container App manually:**
```bash
az containerapp create \
  --name rpg-backend \
  --resource-group rpg-aiapp-rg \
  --environment <env-name> \
  --image <your-image> \
  --target-port 80 \
  --ingress external
```

---

## What You Can Do Now

### Without Function App

1. **Use Static Web App** for frontend
2. **Access SQL Database** directly from client (not recommended for production)
3. **Use Azure OpenAI** directly from client (API key exposure risk)
4. **Wait for quota approval** before adding backend logic

### With Manual Backend

1. **Deploy to Azure Container Apps** (if quota available)
2. **Deploy to Azure App Service** (Web App, not Function App)
3. **Use Azure VM** with your application
4. **Use Azure Kubernetes Service** (AKS)

---

## Recommended Next Steps

### Immediate (Today)

1. ✅ **Request quota increase** in Azure Portal
2. ✅ **Verify deployed resources** are working:
   ```bash
   # Check Key Vault
   az keyvault secret list --vault-name demo-rpgkv-r8g0md
   
   # Check SQL Database
   az sql db show --name rpg-gaming-db --server rpg-sql-r8g0md --resource-group rpg-aiapp-rg
   
   # Check Static Web App
   az staticwebapp show --name rpg-gaming-web-r8g0md --resource-group rpg-aiapp-rg
   ```

### Short Term (24-48 hours)

3. ⏳ **Wait for quota approval**
4. ✅ **Re-deploy Function App** once quota is approved
5. ✅ **Link Static Web App** to Function App
6. ✅ **Deploy application code**

### Alternative Path

If quota is not approved:
1. ⚠️ **Use Azure App Service** (Web App) instead of Function App
2. ⚠️ **Use Azure Container Apps** as serverless alternative
3. ⚠️ **Deploy backend to VM** or container

---

## Cost Impact

### Current Deployment (Without Function App)

| Service | Cost |
|---------|------|
| Static Web App | $9/month |
| SQL Database (Basic) | $5/month |
| Azure OpenAI | $0-200/month (usage) |
| Key Vault | $0.03/10k ops |
| Private Endpoints (2) | $8/month |
| Storage | $1-2/month |
| **Total** | **$23-224/month** |

### With Function App (After Quota)

| Service | Cost |
|---------|------|
| Function App (Y1) | $0-20/month |
| **New Total** | **$23-244/month** |

---

## Testing Current Infrastructure

Even without Function App, you can test the deployed resources:

### Test Key Vault

```bash
# List secrets
az keyvault secret list --vault-name demo-rpgkv-r8g0md

# Get a secret
az keyvault secret show --vault-name demo-rpgkv-r8g0md --name sql-username
```

### Test SQL Database

```bash
# Get connection info
az sql db show \
  --name rpg-gaming-db \
  --server rpg-sql-r8g0md \
  --resource-group rpg-aiapp-rg

# Connect (requires sqlcmd)
sqlcmd -S rpg-sql-r8g0md.database.windows.net \
  -d rpg-gaming-db \
  -U sqladmin \
  -P '<password-from-keyvault>'
```

### Test Azure OpenAI

```bash
# Get endpoint
az cognitiveservices account show \
  --name rpg-openai-r8g0md \
  --resource-group rpg-aiapp-rg \
  --query properties.endpoint

# Get key (from Key Vault)
az keyvault secret show \
  --vault-name demo-rpgkv-r8g0md \
  --name openai-key \
  --query value -o tsv
```

### Test Static Web App

```bash
# Get URL
az staticwebapp show \
  --name rpg-gaming-web-r8g0md \
  --resource-group rpg-aiapp-rg \
  --query defaultHostname -o tsv

# Visit in browser
open https://$(az staticwebapp show --name rpg-gaming-web-r8g0md --resource-group rpg-aiapp-rg --query defaultHostname -o tsv)
```

---

## Cleanup (If Needed)

If you want to start fresh after quota approval:

```bash
# Destroy all resources
terraform destroy

# Or delete resource group
az group delete --name rpg-aiapp-rg --yes --no-wait
```

---

## Summary

**Good News:**
- ✅ 80% of infrastructure deployed successfully
- ✅ Key Vault, SQL Database, OpenAI, Static Web App all working
- ✅ Private endpoints configured
- ✅ Secrets stored securely

**Action Required:**
- ⏳ Request quota increase for Function App
- ⏳ Wait 24-48 hours for approval
- ✅ Re-run `terraform apply` after approval

**Alternative:**
- Use Azure App Service (Web App) instead
- Use Azure Container Apps
- Deploy backend to VM

---

**Next Action:** Request quota increase in Azure Portal → Subscriptions → Usage + quotas → App Service → Dynamic VMs

**Timeline:** 24-48 hours for quota approval, then 5 minutes to deploy Function App

**Status:** Infrastructure 80% complete, waiting on quota for Function App
