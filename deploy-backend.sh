#!/bin/bash

# Deploy Python Backend to Function App
set -e

echo "🚀 Deploying Python Backend to Function App..."

# Check if infrastructure is deployed
cd rpg-aiapp-infra
if ! terraform output function_app_name >/dev/null 2>&1; then
  echo "❌ Infrastructure not deployed. Running terraform apply first..."
  terraform apply -auto-approve
fi

FUNCTION_APP_NAME=$(terraform output -raw function_app_name)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
cd ..

echo "📋 Deployment Details:"
echo "  Function App: $FUNCTION_APP_NAME"
echo "  Resource Group: $RESOURCE_GROUP"

# Navigate to Python backend
cd demo-rpg-aiapp/dev/rpg-backend-python

# Update keyvault_helper.py to use our infrastructure
echo "⚙️  Updating Key Vault helper..."
cp keyvault_helper_updated.py keyvault_helper.py

# Create local.settings.json from infrastructure
echo "⚙️  Configuring Function App settings..."
KEY_VAULT_URI=$(cd ../../../rpg-aiapp-infra && terraform output -raw key_vault_name | xargs -I {} echo "https://{}.vault.azure.net/")

cat > local.settings.json << EOF
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "FUNCTIONS_EXTENSION_VERSION": "~4",
    "KEY_VAULT_URI": "$KEY_VAULT_URI",
    "AZURE_OPENAI_DEPLOYMENT": "gpt-4o"
  }
}
EOF

echo "📝 Function App will use Key Vault: $KEY_VAULT_URI"

# Check if Azure Functions Core Tools is installed
if ! command -v func &> /dev/null; then
  echo "❌ Azure Functions Core Tools not found. Installing..."
  npm install -g azure-functions-core-tools@4 --unsafe-perm true
fi

# Deploy to Function App
echo "📦 Deploying Python code..."
func azure functionapp publish $FUNCTION_APP_NAME --python

echo "✅ Python backend deployed successfully!"
echo "🌐 Function App URL: https://$FUNCTION_APP_NAME.azurewebsites.net"