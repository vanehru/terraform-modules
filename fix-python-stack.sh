#!/bin/bash

# Fix Function App Python Stack Configuration
set -e

echo "🔧 Fixing Python Stack Configuration..."

FUNCTION_APP_NAME="demo-rpg-func-l0svei"
PUBLISH_USER='$demo-rpg-func-l0svei'
PUBLISH_PASS='9cl69AEK0ZauqGM7F1xtWfv3CL4digh6Sbqb8erl0JdMWln2xl0YghPYqi8y'

# Update site config with Python stack
echo "⚙️  Setting Python 3.9 runtime stack..."
curl -X PUT "https://$FUNCTION_APP_NAME.scm.azurewebsites.net/api/settings" \
  --user "$PUBLISH_USER:$PUBLISH_PASS" \
  -H "Content-Type: application/json" \
  -d '{
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "FUNCTIONS_EXTENSION_VERSION": "~4",
    "KEY_VAULT_URI": "https://demo-rpgkv123.vault.azure.net/",
    "AZURE_OPENAI_DEPLOYMENT": "gpt-4o",
    "WEBSITE_RUN_FROM_PACKAGE": "1",
    "linuxFxVersion": "Python|3.9"
  }'

echo ""
echo "🔄 Restarting Function App..."
curl -X POST "https://$FUNCTION_APP_NAME.scm.azurewebsites.net/api/functions/host/restart" \
  --user "$PUBLISH_USER:$PUBLISH_PASS"

echo ""
echo "✅ Python stack configuration updated!"
echo ""
echo "📋 Manual Steps Required in Azure Portal:"
echo "1. Go to Function App → Configuration → General settings"
echo "2. Runtime stack: Select 'Python'"
echo "3. Version: Select '3.9'"
echo "4. Click 'Save'"
echo "5. Restart the Function App"
echo ""
echo "🌐 Function App: https://portal.azure.com/#resource/subscriptions/[sub]/resourceGroups/rpg-aiapp-rg/providers/Microsoft.Web/sites/demo-rpg-func-l0svei"