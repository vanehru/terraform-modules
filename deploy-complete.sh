#!/bin/bash

# Complete deployment script for RPG AI App
set -e

echo "🎮 RPG AI App - Complete Deployment"
echo "=================================="

# Step 1: Deploy Infrastructure
echo "1️⃣  Deploying Infrastructure..."
cd rpg-aiapp-infra
terraform apply -auto-approve
echo "✅ Infrastructure deployed!"

# Step 2: Deploy Python Backend
echo ""
echo "2️⃣  Deploying Python Backend..."
cd ..
chmod +x deploy-backend.sh
./deploy-backend.sh
echo "✅ Backend deployed!"

# Step 3: Deploy Vue.js Frontend
echo ""
echo "3️⃣  Deploying Vue.js Frontend..."
chmod +x deploy-frontend.sh
./deploy-frontend.sh
echo "✅ Frontend deployed!"

# Step 4: Show deployment summary
echo ""
echo "🎉 Deployment Complete!"
echo "======================"

cd rpg-aiapp-infra
terraform output integration_summary
terraform output next_steps

echo ""
echo "🔗 Application URLs:"
echo "  Frontend: $(terraform output -raw static_web_app_url)"
echo "  Backend API: $(terraform output -raw function_app_url)"
echo ""
echo "🔐 Azure Resources:"
echo "  Resource Group: $(terraform output -raw resource_group_name)"
echo "  Key Vault: $(terraform output -raw key_vault_name)"
echo "  SQL Database: $(terraform output -raw sql_server_name)"
echo "  OpenAI Account: $(terraform output -raw openai_account_name)"