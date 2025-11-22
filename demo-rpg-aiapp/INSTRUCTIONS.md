# 📖 RPG AI Application - Complete Setup Instructions

This guide walks you through setting up and deploying the RPG AI Application from scratch.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Configure GitHub Secrets](#configure-github-secrets)
4. [Deploy Infrastructure](#deploy-infrastructure)
5. [Deploy Applications](#deploy-applications)
6. [Verify Deployment](#verify-deployment)
7. [Local Development](#local-development)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

Install the following tools before starting:

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform (version 1.6.0 or higher)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Node.js (version 18 or higher)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Python 3.11
sudo apt install python3.11 python3.11-venv python3-pip

# Azure Functions Core Tools
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh

# jq (for JSON parsing)
sudo apt install jq
```

### Verify Installations

```bash
az --version          # Azure CLI
terraform --version   # Terraform
node --version        # Node.js (should be >= 18)
python3 --version     # Python (should be >= 3.11)
func --version        # Azure Functions Core Tools
gh --version          # GitHub CLI
```

### Required Accounts

- ✅ Azure subscription with Owner or Contributor access
- ✅ GitHub account with repository access
- ✅ GitHub Actions enabled on repository

---

## Initial Setup

### 1. Clone Repository

```bash
git clone <your-repository-url>
cd demo-rpg-aiapp
```

### 2. Configure Azure

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set active subscription
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"

# Verify current subscription
az account show --output table
```

### 3. Configure GitHub CLI

```bash
# Login to GitHub
gh auth login

# Follow prompts to authenticate
# Choose: GitHub.com > HTTPS > Login with web browser
```

---

## Configure GitHub Secrets

GitHub secrets are required for automated deployments. Follow these steps carefully.

### Step 1: Create Azure Service Principal

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-actions-rpg-app" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth > azure-credentials.json

# View the created credentials (DO NOT SHARE!)
cat azure-credentials.json
```

**Expected output format:**
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  ...
}
```

### Step 2: Extract Individual Values

```bash
# Extract values from JSON
CLIENT_ID=$(cat azure-credentials.json | jq -r '.clientId')
CLIENT_SECRET=$(cat azure-credentials.json | jq -r '.clientSecret')
SUBSCRIPTION_ID=$(cat azure-credentials.json | jq -r '.subscriptionId')
TENANT_ID=$(cat azure-credentials.json | jq -r '.tenantId')

# Display values (verify they're not empty)
echo "Client ID: $CLIENT_ID"
echo "Client Secret: $CLIENT_SECRET"
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"
```

### Step 3: Set GitHub Secrets

```bash
# Set AZURE_CREDENTIALS (entire JSON)
gh secret set AZURE_CREDENTIALS < azure-credentials.json

# Set individual secrets for Terraform
gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
gh secret set AZURE_CLIENT_SECRET --body "$CLIENT_SECRET"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"

# Verify secrets were created
gh secret list
```

**Expected output:**
```
AZURE_CLIENT_ID          Updated 2025-11-22
AZURE_CLIENT_SECRET      Updated 2025-11-22
AZURE_CREDENTIALS        Updated 2025-11-22
AZURE_SUBSCRIPTION_ID    Updated 2025-11-22
AZURE_TENANT_ID          Updated 2025-11-22
```

### Step 4: Clean Up Sensitive Files

```bash
# Remove credentials file (IMPORTANT!)
rm azure-credentials.json

# Verify it's deleted
ls -la azure-credentials.json 2>/dev/null || echo "✅ Credentials file safely deleted"
```

---

## Deploy Infrastructure

### Option A: Automated Deployment via GitHub Actions (Recommended)

This is the easiest method for first-time deployment.

#### 1. Push Code to GitHub

```bash
# Commit any changes
git add .
git commit -m "Initial setup with CI/CD workflows"

# Push to main branch (triggers automatic deployment)
git push origin main
```

#### 2. Monitor Deployment

```bash
# Watch the workflow in real-time
gh run watch

# Or view in browser
gh run list --limit 1
gh browse --repo <your-org>/<your-repo>/actions
```

#### 3. Get Static Web App Token (After First Deployment)

Once infrastructure is deployed, you need to set the Static Web App deployment token:

```bash
# Navigate to infrastructure directory
cd infra

# Get the token from Terraform output
TOKEN=$(terraform output -raw static_web_app_deployment_token)

# Set as GitHub secret
gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --body "$TOKEN"

# Verify
gh secret list | grep AZURE_STATIC_WEB_APPS_API_TOKEN
```

### Option B: Manual Local Deployment

If you prefer to deploy manually or need more control:

#### 1. Initialize Terraform

```bash
cd infra

# Initialize Terraform (downloads providers)
terraform init

# Verify initialization
terraform version
```

#### 2. Create Terraform Variables File

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Required variables:**
```hcl
project_name = "rpgai"
environment  = "dev"
location     = "eastus"
instance     = "001"

# Add any other required variables
```

#### 3. Plan and Apply

```bash
# Preview changes
terraform plan -var-file="environments/dev.tfvars"

# Apply changes (creates Azure resources)
terraform apply -var-file="environments/dev.tfvars"

# Type 'yes' when prompted
```

#### 4. Save Outputs

```bash
# Display all outputs
terraform output

# Save to file
terraform output -json > terraform-outputs.json

# View specific outputs
echo "Key Vault URL: $(terraform output -raw keyvault_url)"
echo "Function App Name: $(terraform output -raw function_app_name)"
echo "Function App URL: $(terraform output -raw function_app_url)"
echo "Static Web App URL: $(terraform output -raw static_web_app_url)"
```

---

## Deploy Applications

### After Infrastructure Deployment

Once infrastructure is deployed (via either method), deploy the applications.

#### Option A: Via GitHub Actions (Recommended)

```bash
# Manually trigger backend deployment
gh workflow run deploy-backend.yml

# Manually trigger frontend deployment
gh workflow run deploy-frontend.yml

# Or trigger complete deployment
gh workflow run deploy-complete.yml

# Monitor progress
gh run watch
```

#### Option B: Using Configuration Scripts

```bash
# Navigate to project root
cd /workspaces/terraform-modules/demo-rpg-aiapp

# Run complete configuration
./scripts/configure-all.sh

# Or configure individually:
./scripts/configure-backend.sh
./scripts/configure-frontend.sh
```

#### Option C: Manual Deployment

**Backend (Azure Functions):**

```bash
cd dev/rpg-backend-python

# Install dependencies
pip install -r requirements.txt --target=".python_packages/lib/site-packages"

# Get Function App name from Terraform
FUNCTION_APP_NAME=$(cd ../../infra && terraform output -raw function_app_name)

# Deploy
func azure functionapp publish $FUNCTION_APP_NAME

# Verify
curl "https://$FUNCTION_APP_NAME.azurewebsites.net/api/SELECTEVENTS"
```

**Frontend (Static Web App):**

```bash
cd dev/rpg-frontend-main

# Create production environment file
FUNCTION_APP_URL=$(cd ../../infra && terraform output -raw function_app_url)
cat > .env.production <<EOF
VUE_APP_API_BASE_URL=${FUNCTION_APP_URL}/api
VUE_APP_ENVIRONMENT=production
EOF

# Install dependencies
npm install

# Build
npm run build

# Deploy (get token from Terraform output)
# Use Azure Portal or Azure CLI to deploy the 'dist' folder
```

---

## Verify Deployment

### 1. Check Azure Resources

```bash
cd infra

# Get resource group name
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# List all resources
az resource list --resource-group $RESOURCE_GROUP --output table

# Check Function App status
FUNCTION_APP_NAME=$(terraform output -raw function_app_name)
az functionapp show --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP --query state
```

### 2. Test Backend API

```bash
# Get Function App URL
FUNCTION_URL=$(cd infra && terraform output -raw function_app_url)

# Test health endpoint
curl "$FUNCTION_URL/api/SELECTEVENTS"

# Expected output: JSON array of events
```

### 3. Access Frontend

```bash
# Get Static Web App URL
FRONTEND_URL=$(cd infra && terraform output -raw static_web_app_url)

# Open in browser
echo "Frontend URL: $FRONTEND_URL"
"$BROWSER" "$FRONTEND_URL"

# Or use xdg-open on Linux
xdg-open "$FRONTEND_URL"
```

### 4. Check GitHub Actions

```bash
# View recent workflow runs
gh run list --limit 5

# View specific run details
gh run view <run-id>

# View logs
gh run view <run-id> --log
```

### 5. Verify Azure Function App Settings

```bash
FUNCTION_APP_NAME=$(cd infra && terraform output -raw function_app_name)
RESOURCE_GROUP=$(cd infra && terraform output -raw resource_group_name)

# List all app settings
az functionapp config appsettings list \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --output table

# Check specific settings
az functionapp config appsettings list \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "[?name=='KEYVAULT_URL'].value" -o tsv
```

---

## Local Development

### Backend Development

```bash
cd dev/rpg-backend-python

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy settings example
cp local.settings.json.example local.settings.json

# Edit with your values (get from Terraform outputs)
nano local.settings.json

# Start local development server
func start

# Test locally
curl http://localhost:7071/api/SELECTEVENTS
```

**local.settings.json example:**
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "KEYVAULT_URL": "https://your-keyvault.vault.azure.net/",
    "AZURE_OPENAI_ENDPOINT": "https://your-openai.openai.azure.com/",
    "AZURE_OPENAI_KEY": "your-api-key",
    "AZURE_OPENAI_DEPLOYMENT": "gpt-4o"
  }
}
```

### Frontend Development

```bash
cd dev/rpg-frontend-main

# Install dependencies
npm install

# Create development environment file
cat > .env.development <<EOF
VUE_APP_API_BASE_URL=http://localhost:7071/api
VUE_APP_ENVIRONMENT=development
EOF

# Start development server
npm run serve

# Open browser to http://localhost:8080
```

### Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/your-feature-name

# 2. Make changes to code

# 3. Test locally
# (Backend and frontend running as shown above)

# 4. Run linting
cd dev/rpg-frontend-main
npm run lint

# 5. Commit changes
git add .
git commit -m "Description of changes"

# 6. Push to GitHub
git push origin feature/your-feature-name

# 7. Create pull request
gh pr create --title "Feature: Your feature name" --body "Description"

# 8. After approval, merge to main (triggers automatic deployment)
gh pr merge
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Terraform "Authorization Failed"

**Error:** `Error: Authorization failed`

**Solution:**
```bash
# Check service principal permissions
CLIENT_ID=$(gh secret get AZURE_CLIENT_ID 2>/dev/null || echo "not-set")
az role assignment list --assignee $CLIENT_ID --output table

# If no roles found, recreate service principal
az ad sp create-for-rbac --name "github-actions-rpg-app" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth
```

#### Issue 2: Function App Deployment Fails

**Error:** `Package deployment failed`

**Solution:**
```bash
# Check Function App logs
FUNCTION_APP_NAME=$(cd infra && terraform output -raw function_app_name)
RESOURCE_GROUP=$(cd infra && terraform output -raw resource_group_name)

az functionapp log tail --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP

# Restart Function App
az functionapp restart --name $FUNCTION_APP_NAME --resource-group $RESOURCE_GROUP

# Redeploy
gh workflow run deploy-backend.yml
```

#### Issue 3: Static Web App Token Invalid

**Error:** `The deployment token is invalid`

**Solution:**
```bash
# Get new token from Azure Portal or Terraform
cd infra
terraform refresh
TOKEN=$(terraform output -raw static_web_app_deployment_token)

# Update GitHub secret
gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --body "$TOKEN"

# Redeploy
gh workflow run deploy-frontend.yml
```

#### Issue 4: Terraform State Lock

**Error:** `Error acquiring the state lock`

**Solution:**
```bash
cd infra

# Force unlock (use with caution!)
terraform force-unlock <lock-id>

# Or delete lock manually if using Azure Storage backend
```

#### Issue 5: GitHub Secrets Not Set

**Error:** Workflow fails with "secret not found"

**Solution:**
```bash
# List current secrets
gh secret list

# Set missing secrets (see "Configure GitHub Secrets" section)
gh secret set AZURE_CREDENTIALS < azure-credentials.json
gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
# ... etc
```

#### Issue 6: Module Not Found in Backend

**Error:** `ModuleNotFoundError: No module named 'pyodbc'`

**Solution:**
```bash
# Ensure requirements.txt is complete
cd dev/rpg-backend-python
cat requirements.txt

# Should include:
# azure-functions
# azure-identity
# azure-keyvault-secrets
# openai
# pyodbc
# passlib[bcrypt]

# Redeploy
gh workflow run deploy-backend.yml
```

#### Issue 7: Frontend Build Fails

**Error:** `Module not found: Error: Can't resolve 'vuetify'`

**Solution:**
```bash
cd dev/rpg-frontend-main

# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Try build locally
npm run build

# If successful, redeploy
gh workflow run deploy-frontend.yml
```

### Get Help

If issues persist:

1. **Check workflow logs:**
   ```bash
   gh run list --limit 5
   gh run view <run-id> --log
   ```

2. **Check Azure Portal:**
   - Function App → Logs
   - Static Web App → Deployment history
   - Key Vault → Access policies

3. **Review documentation:**
   - [README.md](README.md) - Project overview
   - [.github/README.md](.github/README.md) - Workflow docs
   - [.github/SECRETS-SETUP.md](.github/SECRETS-SETUP.md) - Secrets guide

4. **Debug mode:**
   Add to workflow YAML:
   ```yaml
   env:
     ACTIONS_STEP_DEBUG: true
     ACTIONS_RUNNER_DEBUG: true
   ```

---

## Next Steps

After successful deployment:

### 1. Configure Application Settings

```bash
# Update Function App settings as needed
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings "YOUR_SETTING=value"
```

### 2. Set Up Monitoring

```bash
# Enable Application Insights
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings "APPINSIGHTS_INSTRUMENTATIONKEY=<key>"
```

### 3. Configure Custom Domain (Optional)

See Azure documentation for adding custom domains to:
- Static Web Apps
- Azure Functions

### 4. Set Up Alerts

Configure alerts in Azure Portal for:
- Function App failures
- High response times
- OpenAI token usage
- SQL Database performance

### 5. Review Security

- [ ] Rotate service principal credentials every 90 days
- [ ] Review Key Vault access policies
- [ ] Enable Azure Defender
- [ ] Configure firewall rules
- [ ] Review CORS settings

---

## Quick Reference Commands

```bash
# Deploy everything
gh workflow run deploy-complete.yml && gh run watch

# View logs
gh run list && gh run view <id> --log

# Test API
curl "$(cd infra && terraform output -raw function_app_url)/api/SELECTEVENTS"

# Restart Function App
az functionapp restart --name $(cd infra && terraform output -raw function_app_name) \
  --resource-group $(cd infra && terraform output -raw resource_group_name)

# Redeploy backend
gh workflow run deploy-backend.yml

# Redeploy frontend
gh workflow run deploy-frontend.yml

# View Terraform outputs
cd infra && terraform output
```

---

## Documentation Links

- **Project Overview**: [README.md](README.md)
- **Workflow Documentation**: [.github/README.md](.github/README.md)
- **Secrets Setup Guide**: [.github/SECRETS-SETUP.md](.github/SECRETS-SETUP.md)
- **Quick Reference**: [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- **Deployment Summary**: [DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md)
- **Configuration Guide**: [CONFIG-SETUP.md](CONFIG-SETUP.md)
- **Architecture**: [infra/ARCHITECTURE.md](infra/ARCHITECTURE.md)

---

## Support

For issues or questions:
- Create an issue in the GitHub repository
- Check existing documentation
- Review Azure Portal logs
- Contact your Azure administrator

**Setup Complete!** 🎉

You now have a fully functional RPG AI Application with automated CI/CD deployment.
