#!/bin/bash

# Deploy Vue.js Frontend to Static Web App
set -e

echo "🚀 Deploying Vue.js Frontend to Static Web App..."

# Check if infrastructure is deployed
cd rpg-aiapp-infra
if ! terraform output function_app_name >/dev/null 2>&1; then
  echo "❌ Infrastructure not deployed. Please run terraform apply first."
  exit 1
fi

# Get infrastructure outputs using basic terraform outputs
STATIC_WEB_APP_NAME=$(terraform output -json | jq -r '.static_web_app_url.value' | sed 's|https://||' | sed 's|\.azurestaticapps\.net||')
FUNCTION_APP_URL=$(terraform output -raw function_app_url)
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
cd ..

echo "📋 Deployment Details:"
echo "  Static Web App: $STATIC_WEB_APP_NAME"
echo "  Backend API: $FUNCTION_APP_URL"
echo "  Resource Group: $RESOURCE_GROUP"

# Navigate to frontend
cd demo-rpg-aiapp/dev/rpg-frontend-main

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf dist/ node_modules/.cache/

# Install dependencies
echo "📦 Installing dependencies..."
npm ci

# Configure environment for production
echo "⚙️  Configuring environment..."
cat > .env.production << EOF
VUE_APP_API_BASE_URL=$FUNCTION_APP_URL
VUE_APP_ENVIRONMENT=production
EOF

# Build for production
echo "🔨 Building frontend..."
if ! npm run build; then
  echo "❌ Build failed. Trying with legacy build..."
  npm run build -- --legacy
fi

# Deploy to Static Web App using npx (no global install needed)
echo "🌐 Deploying to Static Web App..."
npx @azure/static-web-apps-cli@latest deploy ./dist \
  --resource-group "$RESOURCE_GROUP" \
  --app-name "$STATIC_WEB_APP_NAME"

echo "✅ Frontend deployed successfully!"
echo "🌐 Static Web App URL: https://$STATIC_WEB_APP_NAME.azurestaticapps.net"