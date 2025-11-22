#!/bin/bash
set -e

echo "Configuring Frontend..."

# Get Terraform outputs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../rpg-aiapp-infra"

FUNCTION_APP_URL=$(terraform output -raw function_app_url)

# Update production environment file
cat > "$SCRIPT_DIR/../rpg-aiapp-dev/rpg-frontend-main/.env.production" <<EOF
VUE_APP_API_BASE_URL=${FUNCTION_APP_URL}/api
VUE_APP_ENVIRONMENT=production
EOF

echo "✅ Frontend .env.production updated"
echo "API URL: ${FUNCTION_APP_URL}/api"

# Optional: Build frontend
read -p "Build frontend now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$SCRIPT_DIR/../rpg-aiapp-dev/rpg-frontend-main"
    npm install
    npm run build
    echo "✅ Frontend built successfully"
fi
