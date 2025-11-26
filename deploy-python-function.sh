#!/bin/bash

# Deploy New Python Function App
set -e

echo "🚀 Creating New Python Function App..."

# Check if ARM environment variables are set
if [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_SUBSCRIPTION_ID" ] || [ -z "$ARM_TENANT_ID" ]; then
    echo "❌ ARM environment variables not set. Please set:"
    echo "export ARM_CLIENT_ID='your-client-id'"
    echo "export ARM_CLIENT_SECRET='your-client-secret'"
    echo "export ARM_SUBSCRIPTION_ID='your-subscription-id'"
    echo "export ARM_TENANT_ID='your-tenant-id'"
    exit 1
fi

cd rpg-aiapp-infra

echo "📦 Creating Python Function App..."
terraform apply -target='module.function_app[0]' -auto-approve

# Get new Function App name
NEW_FUNCTION_APP=$(terraform output -raw function_app_name)
echo ""
echo "✅ New Python Function App created: $NEW_FUNCTION_APP"

# Deploy Python code to new Function App
echo ""
echo "📤 Deploying Python code..."
cd ../demo-rpg-aiapp/dev/rpg-backend-python

# Create new ZIP
zip -r backend-python-deploy.zip . -x "*.git*" "__pycache__/*" "*.pyc" "local.settings.json"

# Get publish profile for new Function App (you'll need to download this)
echo ""
echo "📋 Next steps:"
echo "1. Go to Azure Portal → Function Apps → $NEW_FUNCTION_APP"
echo "2. Download publish profile"
echo "3. Deploy using: backend-python-deploy.zip"
echo ""
echo "🌐 New Function App URL: https://$NEW_FUNCTION_APP.azurewebsites.net"