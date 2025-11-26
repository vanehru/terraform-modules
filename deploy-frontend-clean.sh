#!/bin/bash

# Deploy Vue.js Frontend to Static Web App (Clean output)
set -e

echo "🚀 Deploying Vue.js Frontend to Static Web App..."

# Check if infrastructure is deployed
cd rpg-aiapp-infra
if ! terraform output function_app_name >/dev/null 2>&1; then
  echo "❌ Infrastructure not deployed. Please run terraform apply first."
  exit 1
fi

# Get infrastructure outputs
STATIC_WEB_APP_NAME=$(terraform output -json | jq -r '.static_web_app_url.value' | sed 's|https://||' | sed 's|\.azurestaticapps\.net||')
FUNCTION_APP_URL=$(terraform output -raw function_app_url)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
cd ..

echo "📋 Deployment Details:"
echo "  Static Web App: $STATIC_WEB_APP_NAME"
echo "  Backend API: $FUNCTION_APP_URL"

# Navigate to frontend
cd demo-rpg-aiapp/dev/rpg-frontend-main

# Clean and install (suppress warnings)
echo "🧹 Cleaning and installing..."
rm -rf dist/ node_modules/.cache/
npm ci --silent --no-audit --no-fund 2>/dev/null

# Configure environment
echo "⚙️  Configuring environment..."
cat > .env.production << EOF
VUE_APP_API_BASE_URL=$FUNCTION_APP_URL
VUE_APP_ENVIRONMENT=production
EOF

# Build (suppress eslint warnings for production)
echo "🔨 Building frontend..."
ESLINT_NO_DEV_ERRORS=true npm run build --silent

# Deploy using npx
echo "🌐 Deploying to Static Web App..."
npx --yes @azure/static-web-apps-cli@latest deploy ./dist \
  --resource-group "$RESOURCE_GROUP" \
  --app-name "$STATIC_WEB_APP_NAME"

echo "✅ Frontend deployed successfully!"
echo "🌐 Static Web App URL: https://$STATIC_WEB_APP_NAME.azurestaticapps.net"