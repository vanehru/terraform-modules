#!/bin/bash

# Build Frontend for Manual Deployment
set -e

echo "🚀 Building Vue.js Frontend for Manual Deployment..."

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

echo "📋 Build Details:"
echo "  Backend API: $FUNCTION_APP_URL"
echo "  Target URL: $STATIC_WEB_APP_URL"

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

echo ""
echo "✅ Frontend built successfully!"
echo "📁 Build output: $(pwd)/dist/"
echo ""
echo "🎯 Manual Deployment Options:"
echo ""
echo "1️⃣  GitHub Integration (Recommended):"
echo "   - Push code to GitHub repository"
echo "   - Connect Static Web App to GitHub repo"
echo "   - Auto-deploy on push"
echo ""
echo "2️⃣  Azure Portal Upload:"
echo "   - Go to: $STATIC_WEB_APP_URL"
echo "   - Use Azure Portal to upload dist/ folder"
echo ""
echo "3️⃣  ZIP Upload:"
echo "   - Create ZIP of dist/ folder"
echo "   - Upload via Azure Portal or CLI"
echo ""
echo "📦 Creating deployment ZIP..."
cd dist
zip -r ../frontend-build.zip . >/dev/null 2>&1
cd ..
echo "   ZIP created: $(pwd)/frontend-build.zip"
echo ""
echo "🔗 Useful Links:"
echo "   Static Web App: $STATIC_WEB_APP_URL"
echo "   Azure Portal: https://portal.azure.com"