# Cleanup and Redeploy Guide

**Date:** 2025-11-25  
**Reason:** Quota limitation for Function App - waiting for quota approval  
**Status:** Ready for cleanup and fresh deployment

---

## Current Situation

### ✅ What's Deployed
- Resource Group: rpg-aiapp-rg
- VNet with 6 subnets
- Key Vault (demo-rpgkv-r8g0md) with private endpoint
- SQL Database (rpg-sql-r8g0md) with private endpoint
- Azure OpenAI (rpg-openai-r8g0md)
- Static Web App (rpg-gaming-web-r8g0md)
- Cloud Shell storage

### ❌ What Failed
- Function App - Quota limitation (Dynamic VMs: 0)

### 📝 What's Been Done
- Function App module commented out in main.tf
- Function App access policy commented out in Key Vault
- Function App outputs commented out in outputs.tf
- Configuration ready for fresh deployment after quota approval

---

## Step 1: Destroy Current Infrastructure

Clean up the partially deployed infrastructure:

```bash
# Destroy all resources
terraform destroy

# Confirm when prompted
# This will take 5-10 minutes
```

**What will be deleted:**
- Resource Group and all resources inside it
- VNet and subnets
- Key Vault (with soft delete - recoverable for 90 days)
- SQL Database
- Azure OpenAI
- Static Web App
- Storage accounts

**What will be preserved:**
- Terraform state file (terraform.tfstate)
- Terraform configuration files
- All your code and modules

---

## Step 2: Wait for Quota Approval

### Check Quota Status

```bash
# Check current quota
az vm list-usage --location "Japan East" -o table | grep -i dynamic

# Or check in Azure Portal
# Subscriptions → Your subscription → Usage + quotas → Search "Dynamic"
```

### Expected Timeline

- **Typical:** 24-48 hours
- **Fast track:** Sometimes instant for small requests
- **Worst case:** 3-5 business days

### You'll Know It's Approved When

```bash
# This command shows quota > 0
az vm list-usage --location "Japan East" -o table | grep -i dynamic
# Output should show: Dynamic VMs: 1 or more
```

---

## Step 3: Uncomment Function App (After Quota Approval)

### 3.1 Uncomment Function App Module

In `main.tf` (around line 120):

```hcl
# Function App Module - Consumption Plan (Y1) with .NET stack
module "function_app" {
  source = "./modules/function-app"

  function_app_name                = "demo-rpg-func-${random_string.suffix.result}"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  storage_account_name             = "rpgfuncstor${random_string.suffix.result}"
  storage_account_tier             = "Standard"
  storage_account_replication_type = "LRS"
  app_service_plan_name            = "demo-rpg-consumption-plan"
  app_service_plan_sku             = "Y1"

  create_managed_identity = true
  enable_vnet_integration = false
  vnet_route_all_enabled  = false

  storage_public_network_access_enabled = true
  storage_network_default_action        = "Allow"
  enable_storage_private_endpoint       = false

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

### 3.2 Uncomment Key Vault Access Policy

In `main.tf` (around line 183):

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

### 3.3 Uncomment Function App Outputs

In `outputs.tf`:

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

### 3.4 (Optional) Link Static Web App

In `main.tf`, Static Web App module:

```hcl
# Uncomment this line after Function App is deployed
function_app_id = module.function_app.function_app_id
```

---

## Step 4: Deploy Everything Fresh

Once quota is approved and Function App is uncommented:

```bash
# 1. Validate configuration
terraform validate

# 2. Format code
terraform fmt -recursive

# 3. Initialize (refresh modules)
terraform init

# 4. Plan deployment
terraform plan -out=full-deployment.tfplan

# 5. Review plan carefully
terraform show full-deployment.tfplan

# 6. Deploy everything
terraform apply full-deployment.tfplan

# This will take 25-35 minutes
```

### Expected Output

```
Apply complete! Resources: 47 added, 0 changed, 0 destroyed.

Outputs:

cloud_shell_file_share = "cloudshell"
cloud_shell_storage_account = "cloudshellr8g0md"
deployment_instructions = <<EOT
  1. Open Azure Cloud Shell: https://shell.azure.com
  2. Configure Cloud Shell to use this VNet:
     az cloud-shell configure \
       --relay-resource-group rpg-aiapp-rg \
       --relay-vnet demo-rpg-vnet \
       --relay-subnet deployment-subnet
  3. Deploy Static Web App:
     swa deploy --app-name rpg-gaming-web-r8g0md
EOT
function_app_name = "demo-rpg-func-r8g0md"
function_app_url = "https://demo-rpg-func-r8g0md.azurewebsites.net"
key_vault_name = "demo-rpgkv-r8g0md"
openai_account_name = "rpg-openai-r8g0md"
resource_group_location = "japaneast"
resource_group_name = "rpg-aiapp-rg"
sql_server_name = "rpg-sql-r8g0md"
static_web_app_url = "https://rpg-gaming-web-r8g0md.azurestaticapps.net"
```

---

## Step 5: Link Static Web App to Function App

After successful deployment:

```bash
# Get Function App ID
FUNC_ID=$(terraform output -raw function_app_id)

# Get Static Web App name
SWA_NAME=$(terraform output -raw static_web_app_name)

# Link them
az staticwebapp functions link \
  --name $SWA_NAME \
  --resource-group rpg-aiapp-rg \
  --function-resource-id $FUNC_ID

# Verify link
az staticwebapp functions show \
  --name $SWA_NAME \
  --resource-group rpg-aiapp-rg
```

---

## Step 6: Deploy Application Code

### Deploy Function App Code

```bash
# Navigate to your function app code
cd your-function-app-code

# Build .NET project
dotnet build --configuration Release

# Publish
dotnet publish --configuration Release --output ./publish

# Deploy to Azure
func azure functionapp publish $(terraform output -raw function_app_name)

# Verify deployment
curl $(terraform output -raw function_app_url)/api/health
```

### Deploy Static Web App Content

```bash
# Navigate to your frontend code
cd your-frontend-code

# Install dependencies
npm install

# Build
npm run build

# Deploy
swa deploy --app-name $(terraform output -raw static_web_app_name) --env production

# Verify deployment
open $(terraform output -raw static_web_app_url)
```

---

## Cleanup Commands

### Destroy Current Partial Deployment

```bash
# Option 1: Terraform destroy (recommended)
terraform destroy

# Option 2: Delete resource group (faster)
az group delete --name rpg-aiapp-rg --yes --no-wait

# Option 3: Targeted destroy (if you want to keep some resources)
terraform destroy -target=module.key_vault
terraform destroy -target=module.sql_database
```

### Verify Cleanup

```bash
# Check if resource group is deleted
az group exists --name rpg-aiapp-rg
# Should return: false

# List all resources (should be empty)
az resource list --resource-group rpg-aiapp-rg
```

### Clean Terraform State

```bash
# After destroy, verify state is clean
terraform show

# If needed, remove state file
rm terraform.tfstate
rm terraform.tfstate.backup
```

---

## Quick Reference: Uncomment Checklist

When quota is approved, uncomment these sections:

- [ ] **main.tf** - Function App module (lines ~120-165)
- [ ] **main.tf** - Key Vault access policy for Function App (lines ~183-186)
- [ ] **main.tf** - Static Web App function_app_id (line ~287) - Optional
- [ ] **outputs.tf** - Function App outputs (lines ~50-65)

---

## Troubleshooting

### Quota Still Not Available

```bash
# Check quota status
az vm list-usage --location "Japan East" -o table | grep -i dynamic

# Try different region
# Change in variables.tf:
variable "azurerm_resource_group_location" {
  default = "East US"  # Try different region
}
```

### Terraform State Issues

```bash
# If state is corrupted
terraform state list

# Remove problematic resources
terraform state rm module.function_app

# Re-import if needed
terraform import module.function_app.azurerm_linux_function_app.function /subscriptions/.../resourceGroups/.../providers/Microsoft.Web/sites/...
```

### Deployment Fails Again

```bash
# Check for errors
terraform plan

# Validate configuration
terraform validate

# Check Azure status
az account show
az account list-locations -o table
```

---

## Timeline

### Current Status
- ✅ Quota request submitted
- ⏳ Waiting for approval (24-48 hours)
- ✅ Configuration ready
- ✅ Cleanup plan ready

### After Quota Approval
1. **5 minutes** - Uncomment Function App code
2. **2 minutes** - Validate and plan
3. **25-35 minutes** - Deploy infrastructure
4. **5 minutes** - Link Static Web App
5. **10 minutes** - Deploy application code
6. **5 minutes** - Test and verify

**Total Time After Approval:** ~1 hour

---

## What You Can Do While Waiting

### 1. Prepare Application Code

- Finalize your .NET/C++ Function App code
- Test locally with Azure Functions Core Tools
- Prepare your Static Web App frontend

### 2. Review Documentation

- Read through the module READMEs
- Review security best practices
- Plan your deployment strategy

### 3. Test Locally

```bash
# Test Function App locally
cd your-function-app-code
func start

# Test Static Web App locally
cd your-frontend-code
npm run dev
```

### 4. Prepare Monitoring

- Plan Application Insights configuration
- Design monitoring dashboards
- Define alerts and thresholds

---

## Summary

**Current State:**
- Infrastructure 80% deployed
- Function App blocked by quota
- Configuration ready for fresh deployment

**Action Required:**
1. ✅ Destroy current partial deployment: `terraform destroy`
2. ⏳ Wait for quota approval (24-48 hours)
3. ✅ Uncomment Function App code (3 locations)
4. ✅ Deploy everything fresh: `terraform apply`

**After Quota Approval:**
- Full deployment in ~1 hour
- All services integrated
- Ready for application code deployment

---

## Commands Summary

```bash
# NOW: Cleanup current deployment
terraform destroy

# AFTER QUOTA APPROVAL: Uncomment Function App in main.tf, then:
terraform validate
terraform plan -out=full.tfplan
terraform apply full.tfplan

# Link Static Web App
az staticwebapp functions link \
  --name $(terraform output -raw static_web_app_name) \
  --resource-group rpg-aiapp-rg \
  --function-resource-id $(terraform output -raw function_app_id)

# Deploy code
func azure functionapp publish $(terraform output -raw function_app_name)
swa deploy --app-name $(terraform output -raw static_web_app_name)
```

---

**Next Action:** Run `terraform destroy` to clean up, then wait for quota approval

**Estimated Wait Time:** 24-48 hours

**Deployment Time After Approval:** ~1 hour for complete infrastructure + application
