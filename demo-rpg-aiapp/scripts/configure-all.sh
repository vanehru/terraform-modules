#!/bin/bash
set -e

echo "==================================="
echo "RPG Application Configuration"
echo "==================================="

# Navigate to Terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../infra"

# Get all outputs
echo "Fetching infrastructure details..."
KEYVAULT_URL=$(terraform output -raw keyvault_url 2>/dev/null || echo "")
FUNCTION_APP_NAME=$(terraform output -raw function_app_name 2>/dev/null || echo "")
FUNCTION_APP_URL=$(terraform output -raw function_app_url 2>/dev/null || echo "")
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
OPENAI_ENDPOINT=$(terraform output -raw openai_endpoint 2>/dev/null || echo "")
STATIC_WEB_APP_URL=$(terraform output -raw static_web_app_url 2>/dev/null || echo "")

# Validate outputs
if [ -z "$FUNCTION_APP_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
    echo "❌ Error: Could not retrieve Terraform outputs."
    echo "Please ensure Terraform has been applied successfully."
    exit 1
fi

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
cat > "$SCRIPT_DIR/../dev/rpg-frontend-main/.env.production" <<EOF
VUE_APP_API_BASE_URL=${FUNCTION_APP_URL}/api
VUE_APP_ENVIRONMENT=production
EOF

echo "✅ Frontend environment file created"

# Update backend local settings example
echo ""
echo "Updating backend local settings example..."
cat > "$SCRIPT_DIR/../dev/rpg-backend-python/local.settings.json.example" <<EOF
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "KEYVAULT_URL": "$KEYVAULT_URL",
    "AZURE_OPENAI_ENDPOINT": "$OPENAI_ENDPOINT",
    "AZURE_OPENAI_KEY": "your-openai-api-key-here",
    "AZURE_OPENAI_DEPLOYMENT": "gpt-4o"
  },
  "Host": {
    "LocalHttpPort": 7071,
    "CORS": "*",
    "CORSCredentials": false
  }
}
EOF

# Optional: Rebuild and deploy frontend
echo ""
read -p "Do you want to build and deploy the frontend now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Building frontend..."
    cd "$SCRIPT_DIR/../dev/rpg-frontend-main"
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
echo "Configuration files updated:"
echo "  - Backend: rpg-backend-python/local.settings.json.example"
echo "  - Frontend: rpg-frontend-main/.env.production"
echo ""
echo "Next steps:"
echo "1. Copy local.settings.json.example to local.settings.json for local development"
echo "2. Test the backend API endpoints"
echo "3. Deploy the frontend build to Static Web App"
echo "4. Verify end-to-end functionality"
