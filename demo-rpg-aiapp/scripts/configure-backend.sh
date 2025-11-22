#!/bin/bash
set -e

echo "Configuring Backend Function App..."

# Get Terraform outputs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../rpg-aiapp-infra"

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

echo "✅ Backend configuration complete!"
echo "Function App: $FUNCTION_APP_NAME"
echo "Key Vault: $KEYVAULT_URL"
