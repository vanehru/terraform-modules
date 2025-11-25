#!/bin/bash

# Recreate Function App with Python Runtime
set -e

echo "🔧 Recreating Function App with Python Runtime..."

# Navigate to terraform directory
cd rpg-aiapp-infra

# First, let's taint the function app to force recreation
echo "🗑️  Marking Function App for recreation..."
terraform taint 'module.function_app[0].azurerm_linux_function_app.function' || true

# Apply to recreate with Python runtime
echo "🚀 Recreating Function App with Python..."
echo "This will:"
echo "  - Delete current .NET Function App"
echo "  - Create new Python Function App"
echo "  - Keep all other resources"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Set environment variables for Terraform
    export ARM_CLIENT_ID="${ARM_CLIENT_ID}"
    export ARM_CLIENT_SECRET="${ARM_CLIENT_SECRET}"
    export ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID}"
    export ARM_TENANT_ID="${ARM_TENANT_ID}"
    
    terraform apply -auto-approve
    
    echo ""
    echo "✅ New Python Function App created!"
    echo "📋 Next steps:"
    echo "1. Deploy Python code again"
    echo "2. Test API endpoints"
else
    echo "❌ Operation cancelled"
fi