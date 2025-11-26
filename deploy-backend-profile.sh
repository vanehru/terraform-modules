#!/bin/bash

# Deploy Python Backend using Publish Profile
set -e

echo "🚀 Deploying Python Backend with Publish Profile..."

# Check for publish profile
if [ -z "$AZURE_PUBLISH_PROFILE" ]; then
  echo "❌ AZURE_PUBLISH_PROFILE environment variable not set"
  echo ""
  echo "🔑 To get your publish profile:"
  echo "1. Go to Azure Portal → Function Apps → demo-rpg-func-l0svei"
  echo "2. Click 'Get publish profile' (top toolbar)"
  echo "3. Download the .publishsettings file"
  echo "4. Copy the entire XML content"
  echo "5. Run: export AZURE_PUBLISH_PROFILE='<paste-xml-content>'"
  echo "6. Then run this script again"
  exit 1
fi

# Navigate to backend
cd demo-rpg-aiapp/dev/rpg-backend-python

echo "📋 Deployment Details:"
echo "  Function App: demo-rpg-func-l0svei"
echo "  Profile: Using publish profile authentication"

# Check if Azure Functions Core Tools is installed
if ! command -v func &> /dev/null; then
  echo "📦 Installing Azure Functions Core Tools..."
  npm install -g azure-functions-core-tools@4 --unsafe-perm true
fi

# Deploy using publish profile
echo "🌐 Deploying to Function App..."
echo "$AZURE_PUBLISH_PROFILE" > .publishsettings
func azure functionapp publish demo-rpg-func-l0svei --publish-settings-file .publishsettings --python
rm -f .publishsettings

echo ""
echo "✅ Backend deployed successfully!"
echo "🌐 Function App URL: https://demo-rpg-func-l0svei.azurewebsites.net"
echo "🔗 API Base: https://demo-rpg-func-l0svei.azurewebsites.net/api/"