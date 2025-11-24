# Configuration Setup Guide

This guide explains how to configure the RPG application after infrastructure deployment.

---

## Backend Configuration (Python Azure Functions)

### Local Development

1. **Copy the example settings file:**
   ```bash
   cd demo-rpg-aiapp/dev/rpg-backend-python
   cp local.settings.json.example local.settings.json
   cp .env.example .env
   ```

2. **Update `local.settings.json` with your values:**
   ```json
   {
     "Values": {
       "KEYVAULT_URL": "https://your-actual-keyvault.vault.azure.net/",
       "AZURE_OPENAI_ENDPOINT": "https://your-actual-openai.openai.azure.com/",
       "AZURE_OPENAI_KEY": "your-actual-api-key",
       "AZURE_OPENAI_DEPLOYMENT": "gpt-4o"
     }
   }
   ```

### Azure Deployment

After Terraform creates the infrastructure, update the Function App settings:

#### Option 1: Using Azure CLI
```bash
# Set Key Vault URL
az functionapp config appsettings set \
  --name <your-function-app-name> \
  --resource-group <your-resource-group> \
  --settings KEYVAULT_URL=https://<your-keyvault>.vault.azure.net/

# Set OpenAI Endpoint
az functionapp config appsettings set \
  --name <your-function-app-name> \
  --resource-group <your-resource-group> \
  --settings AZURE_OPENAI_ENDPOINT=https://<your-openai>.openai.azure.com/

# Set OpenAI Key (use Key Vault reference for security)
az functionapp config appsettings set \
  --name <your-function-app-name> \
  --resource-group <your-resource-group> \
  --settings AZURE_OPENAI_KEY=@Microsoft.KeyVault(SecretUri=https://<keyvault>.vault.azure.net/secrets/openai-key/)
```

#### Option 2: Using Terraform Outputs

Add this script after Terraform deployment:

**`scripts/configure-backend.sh`**
```bash
#!/bin/bash

# Get Terraform outputs
KEYVAULT_URL=$(terraform output -raw keyvault_url)
FUNCTION_APP_NAME=$(terraform output -raw function_app_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
OPENAI_ENDPOINT=$(terraform output -raw openai_endpoint)

# Configure Function App
az functionapp config appsettings set \
  --name "$FUNCTION_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --settings \
    KEYVAULT_URL="$KEYVAULT_URL" \
    AZURE_OPENAI_ENDPOINT="$OPENAI_ENDPOINT" \
    AZURE_OPENAI_KEY="@Microsoft.KeyVault(SecretUri=${KEYVAULT_URL}secrets/openai-key/)" \
    AZURE_OPENAI_DEPLOYMENT="gpt-4o"

echo "Backend configuration complete!"
```

#### Option 3: Update Terraform Module

Add to your Function App module:

```hcl
# modules/function-app/main.tf

resource "azurerm_linux_function_app" "main" {
  # ... existing configuration ...

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "python"
    KEYVAULT_URL                   = var.keyvault_url
    AZURE_OPENAI_ENDPOINT          = var.openai_endpoint
    AZURE_OPENAI_KEY               = "@Microsoft.KeyVault(SecretUri=${var.keyvault_url}secrets/openai-key/)"
    AZURE_OPENAI_DEPLOYMENT        = var.openai_deployment_name
    WEBSITE_RUN_FROM_PACKAGE       = "1"
  }
}
```

---

## Frontend Configuration (Vue.js)

### Local Development

1. **Copy the environment file:**
   ```bash
   cd demo-rpg-aiapp/dev/rpg-frontend-main
   cp .env.example .env.local
   ```

2. **Update `.env.local` with your backend URL:**
   ```env
   VUE_APP_API_BASE_URL=http://localhost:7071/api
   ```

### Production Deployment

#### Option 1: Manual Update

1. **Update `.env.production`:**
   ```env
   VUE_APP_API_BASE_URL=https://your-function-app-name.azurewebsites.net/api
   ```

2. **Rebuild the application:**
   ```bash
   npm run build
   ```

#### Option 2: Using Terraform Outputs

**`scripts/configure-frontend.sh`**
```bash
#!/bin/bash

# Get Function App URL from Terraform
FUNCTION_APP_URL=$(terraform output -raw function_app_url)

# Update production environment file
cat > demo-rpg-aiapp/dev/rpg-frontend-main/.env.production <<EOF
VUE_APP_API_BASE_URL=${FUNCTION_APP_URL}/api
VUE_APP_ENVIRONMENT=production
EOF

# Rebuild frontend
cd rpg-aiapp-dev/rpg-frontend-main
npm run build

echo "Frontend configuration complete!"
echo "API URL: ${FUNCTION_APP_URL}/api"
```

#### Option 3: Static Web App Configuration

If using Azure Static Web Apps, configure via `staticwebapp.config.json`:

```json
{
  "routes": [],
  "navigationFallback": {
    "rewrite": "/index.html"
  },
  "globalHeaders": {
    "content-security-policy": "default-src 'self'"
  },
  "mimeTypes": {
    ".json": "application/json"
  },
  "environmentVariables": {
    "VUE_APP_API_BASE_URL": "https://your-function-app.azurewebsites.net/api"
  }
}
```

---

## Complete Automation Script

Create a master configuration script that runs after Terraform:

**`scripts/configure-all.sh`**
```bash
#!/bin/bash
set -e

echo "==================================="
echo "RPG Application Configuration"
echo "==================================="

# Navigate to Terraform directory
cd rpg-aiapp-infra

# Get all outputs
echo "Fetching infrastructure details..."
KEYVAULT_URL=$(terraform output -raw keyvault_url)
FUNCTION_APP_NAME=$(terraform output -raw function_app_name)
FUNCTION_APP_URL=$(terraform output -raw function_app_url)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
OPENAI_ENDPOINT=$(terraform output -raw openai_endpoint)
STATIC_WEB_APP_URL=$(terraform output -raw static_web_app_url)

echo ""
echo "Infrastructure Details:"
echo "  Key Vault: $KEYVAULT_URL"
echo "  Function App: $FUNCTION_APP_NAME"
echo "  Function App URL: $FUNCTION_APP_URL"
echo "  Static Web App: $STATIC_WEB_APP_URL"
echo ""

# Configure Backend
echo "Configuring Backend Function App..."
az functionapp config appsettings set \
  --name "$FUNCTION_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --settings \
    KEYVAULT_URL="$KEYVAULT_URL" \
    AZURE_OPENAI_ENDPOINT="$OPENAI_ENDPOINT" \
    AZURE_OPENAI_KEY="@Microsoft.KeyVault(SecretUri=${KEYVAULT_URL}secrets/openai-key/)" \
    AZURE_OPENAI_DEPLOYMENT="gpt-4o" \
  --output none

echo "✅ Backend configured successfully"

# Configure Frontend
echo ""
echo "Configuring Frontend..."
cat > ../demo-rpg-aiapp/dev/rpg-frontend-main/.env.production <<EOF
VUE_APP_API_BASE_URL=${FUNCTION_APP_URL}/api
VUE_APP_ENVIRONMENT=production
EOF

echo "✅ Frontend environment file created"

# Optional: Rebuild and deploy frontend
read -p "Do you want to build and deploy the frontend now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Building frontend..."
    cd ../demo-rpg-aiapp/dev/rpg-frontend-main
    npm install
    npm run build
    echo "✅ Frontend built successfully"
fi

echo ""
echo "==================================="
echo "Configuration Complete!"
echo "==================================="
echo ""
echo "Backend API: ${FUNCTION_APP_URL}/api"
echo "Frontend URL: ${STATIC_WEB_APP_URL}"
echo ""
echo "Next steps:"
echo "1. Test the backend API endpoints"
echo "2. Deploy the frontend build to Static Web App"
echo "3. Verify end-to-end functionality"
```

Make it executable:
```bash
chmod +x scripts/configure-all.sh
```

---

## Configuration Files Reference

### Backend Files
- `.env.example` - Template for environment variables
- `local.settings.json.example` - Template for Azure Functions local settings
- `local.settings.json` - Actual local settings (gitignored)

### Frontend Files
- `.env.example` - Template with default values
- `.env.development` - Development environment settings
- `.env.production` - Production environment settings (update after deployment)
- `.env.local` - Local overrides (gitignored)

### Configuration Priority (Frontend)
1. `.env.local` (highest priority, gitignored)
2. `.env.production` or `.env.development` (based on NODE_ENV)
3. `.env`
4. `.env.example` (lowest priority, for reference only)

---

## Security Best Practices

### Backend
1. **Never commit `local.settings.json`** - Already in `.gitignore`
2. **Use Key Vault references** for secrets in Azure
3. **Use Managed Identity** for Key Vault access (no passwords needed)
4. **Rotate keys regularly** via Key Vault

Example Key Vault reference:
```
@Microsoft.KeyVault(SecretUri=https://myvault.vault.azure.net/secrets/mysecret/)
```

### Frontend
1. **Never commit `.env.local`** or `.env.production` with real URLs
2. **Keep `.env.example`** updated as template
3. **Use environment-specific builds** for different environments
4. **Don't expose sensitive keys** in frontend code

---

## Testing Configuration

### Backend
```bash
# Test locally
cd demo-rpg-aiapp/dev/rpg-backend-python
func start

# Test endpoints
curl http://localhost:7071/api/SELECTEVENTS
```

### Frontend
```bash
# Test locally
cd demo-rpg-aiapp/dev/rpg-frontend-main
npm run serve

# Build for production
npm run build

# Preview production build
npm install -g serve
serve -s dist
```

---

## Troubleshooting

### Backend Issues

**Problem:** "KEYVAULT_URL environment variable not set"
- **Solution:** Check `local.settings.json` or Azure Function App settings

**Problem:** "Cannot connect to Key Vault"
- **Solution:** Verify Managed Identity is enabled and has proper permissions

### Frontend Issues

**Problem:** API calls fail with CORS error
- **Solution:** Check Function App CORS settings

**Problem:** Wrong API URL
- **Solution:** Verify `.env.production` has correct URL and rebuild

---

## Post-Deployment Checklist

- [ ] Terraform infrastructure deployed successfully
- [ ] Run `configure-all.sh` script
- [ ] Backend environment variables set in Azure
- [ ] Frontend `.env.production` updated
- [ ] Frontend rebuilt with production config
- [ ] Frontend deployed to Static Web App
- [ ] Test user registration
- [ ] Test user login
- [ ] Test game functionality
- [ ] Verify OpenAI integration
- [ ] Check logs for errors

---

## Quick Reference Commands

```bash
# After Terraform deployment
cd scripts
./configure-all.sh

# Verify backend configuration
az functionapp config appsettings list \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --query "[?name=='KEYVAULT_URL']"

# Update single backend setting
az functionapp config appsettings set \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --settings SETTING_NAME=value

# View current frontend config
cat demo-rpg-aiapp/dev/rpg-frontend-main/.env.production

# Rebuild frontend
cd rpg-aiapp-dev/rpg-frontend-main
npm run build
```
