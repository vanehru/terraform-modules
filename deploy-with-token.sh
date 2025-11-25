#!/bin/bash

# Deploy Frontend using Static Web App Deployment Token
set -e

echo "🚀 Deploying Vue.js Frontend with Deployment Token..."

# Check for deployment token
if [ -z "$SWA_DEPLOYMENT_TOKEN" ]; then
  echo "❌ SWA_DEPLOYMENT_TOKEN environment variable not set"
  echo ""
  echo "🔑 To get your deployment token:"
  echo "1. Go to Azure Portal → Static Web Apps → rpg-gaming-web"
  echo "2. Click 'Manage deployment token'"
  echo "3. Copy the token"
  echo "4. Run: export SWA_DEPLOYMENT_TOKEN='your-token-here'"
  echo "5. Then run this script again"
  exit 1
fi

# Check if infrastructure is deployed
cd rpg-aiapp-infra
if ! terraform output function_app_name >/dev/null 2>&1; then
  echo "❌ Infrastructure not deployed. Please run terraform apply first."
  exit 1
fi

# Get infrastructure outputs
FUNCTION_APP_URL=$(terraform output -raw function_app_url)
STATIC_WEB_APP_URL=$(terraform output -raw static_web_app_url)
cd ..

echo "📋 Deployment Details:"
echo "  Backend API: $FUNCTION_APP_URL"
echo "  Target URL: $STATIC_WEB_APP_URL"
echo "  Token: ${SWA_DEPLOYMENT_TOKEN:0:20}..."

# Navigate to frontend
cd demo-rpg-aiapp/dev/rpg-frontend-main

# Clean and install
echo "🧹 Cleaning and installing..."
rm -rf dist/ node_modules/.cache/
npm ci --silent --no-audit --no-fund 2>/dev/null

# Configure environment
echo "⚙️  Configuring environment..."
cat > .env.production << EOF
VUE_APP_API_BASE_URL=$FUNCTION_APP_URL
VUE_APP_ENVIRONMENT=production
EOF

# Build
echo "🔨 Building frontend..."
ESLINT_NO_DEV_ERRORS=true npm run build --silent

# Deploy using token
echo "🌐 Deploying to Static Web App..."
npx --yes @azure/static-web-apps-cli@latest deploy ./dist \
  --deployment-token "$SWA_DEPLOYMENT_TOKEN" \
  --verbose

echo ""
echo "✅ Frontend deployed successfully!"
echo "🌐 Static Web App URL: $STATIC_WEB_APP_URL"