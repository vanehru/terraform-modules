#!/bin/bash

# Deploy only the infrastructure
set -e

echo "🏗️  Deploying Infrastructure to Japan East..."
echo "============================================="

cd rpg-aiapp-infra

# Deploy infrastructure
echo "📦 Running terraform apply..."
terraform apply -auto-approve

echo ""
echo "✅ Infrastructure deployed successfully!"
echo ""

# Show key outputs
echo "🔗 Infrastructure Summary:"
echo "  Resource Group: $(terraform output -raw resource_group_name)"
echo "  Function App: $(terraform output -raw function_app_name)"
echo "  Key Vault: $(terraform output -raw key_vault_name)"
echo "  SQL Server: $(terraform output -raw sql_server_name)"
echo "  OpenAI Account: $(terraform output -raw openai_account_name)"

if terraform output function_app_url >/dev/null 2>&1; then
  echo "  Function App URL: $(terraform output -raw function_app_url)"
fi

if terraform output static_web_app_url >/dev/null 2>&1; then
  echo "  Static Web App URL: $(terraform output -raw static_web_app_url)"
fi

echo ""
echo "🎯 Next Steps:"
echo "  1. Run: ./deploy-backend.sh"
echo "  2. Run: ./deploy-frontend.sh"
echo "  3. Or run: ./deploy-complete.sh (will skip infra)"