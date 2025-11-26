#!/bin/bash

# Update Function App Settings via REST API
set -e

echo "🔧 Updating Function App Runtime Settings..."

# Function App details
FUNCTION_APP_NAME="demo-rpg-func-l0svei"
PUBLISH_PROFILE_USER='$demo-rpg-func-l0svei'
PUBLISH_PROFILE_PASS='9cl69AEK0ZauqGM7F1xtWfv3CL4digh6Sbqb8erl0JdMWln2xl0YghPYqi8y'

# Get current app settings
echo "📋 Getting current settings..."
CURRENT_SETTINGS=$(curl -s "https://$FUNCTION_APP_NAME.scm.azurewebsites.net/api/settings" \
  --user "$PUBLISH_PROFILE_USER:$PUBLISH_PROFILE_PASS")

echo "Current settings retrieved"

# Update settings with Python runtime
echo "⚙️  Updating to Python runtime..."
curl -X POST "https://$FUNCTION_APP_NAME.scm.azurewebsites.net/api/settings" \
  --user "$PUBLISH_PROFILE_USER:$PUBLISH_PROFILE_PASS" \
  -H "Content-Type: application/json" \
  -d '{
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "FUNCTIONS_EXTENSION_VERSION": "~4",
    "KEY_VAULT_URI": "https://demo-rpgkv123.vault.azure.net/",
    "AZURE_OPENAI_DEPLOYMENT": "gpt-4o",
    "WEBSITE_RUN_FROM_PACKAGE": "1"
  }'

echo ""
echo "🔄 Restarting Function App..."
curl -X POST "https://$FUNCTION_APP_NAME.scm.azurewebsites.net/api/functions/host/restart" \
  --user "$PUBLISH_PROFILE_USER:$PUBLISH_PROFILE_PASS"

echo ""
echo "✅ Function App updated with Python runtime!"
echo "⏳ Wait 30 seconds for restart to complete..."
sleep 30

echo "🧪 Testing API endpoint..."
curl https://$FUNCTION_APP_NAME.azurewebsites.net/api/SELECTALLPLAYER