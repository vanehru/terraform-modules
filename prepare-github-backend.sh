#!/bin/bash

# Prepare Python Backend for GitHub Deployment
set -e

echo "📦 Preparing Python Backend for GitHub..."

# Navigate to backend
cd demo-rpg-aiapp/dev/rpg-backend-python

# Update keyvault helper
echo "⚙️  Updating Key Vault helper..."
cp ../../../keyvault_helper_updated.py keyvault_helper.py

# Create .gitignore
echo "📝 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Azure Functions artifacts
bin
obj
appsettings.json
local.settings.json

# Environment variables
.env
.venv
env/
venv/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
EOF

# Create GitHub Actions workflow
echo "🔄 Creating GitHub Actions workflow..."
mkdir -p .github/workflows

cat > .github/workflows/deploy-function-app.yml << 'EOF'
name: Deploy Python Function App

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

env:
  AZURE_FUNCTIONAPP_PACKAGE_PATH: '.'
  PYTHON_VERSION: '3.9'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - name: 'Checkout GitHub Action'
      uses: actions/checkout@v3

    - name: Setup Python ${{ env.PYTHON_VERSION }} Environment
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: 'Resolve Project Dependencies Using Pip'
      shell: bash
      run: |
        pushd './${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}'
        python -m pip install --upgrade pip
        pip install -r requirements.txt --target=".python_packages/lib/site-packages"
        popd

    - name: 'Run Azure Functions Action'
      uses: Azure/functions-action@v1
      with:
        app-name: ${{ secrets.AZURE_FUNCTIONAPP_NAME }}
        package: ${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        publish-profile: ${{ secrets.AZURE_FUNCTIONAPP_PUBLISH_PROFILE }}
        scm-do-build-during-deployment: true
        enable-oryx-build: true
EOF

# Create README for GitHub setup
echo "📖 Creating deployment README..."
cat > GITHUB-DEPLOYMENT.md << 'EOF'
# GitHub Deployment Setup

## 1. Create GitHub Repository

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/rpg-backend.git
git push -u origin main
```

## 2. Get Function App Publish Profile

1. Go to Azure Portal → Function Apps → `demo-rpg-func-l0svei`
2. Click "Get publish profile" (top toolbar)
3. Download the `.publishsettings` file
4. Copy the entire XML content

## 3. Configure GitHub Secrets

In your GitHub repository:

1. Go to Settings → Secrets and variables → Actions
2. Add these secrets:

**AZURE_FUNCTIONAPP_NAME**
```
demo-rpg-func-l0svei
```

**AZURE_FUNCTIONAPP_PUBLISH_PROFILE**
```
[Paste the entire XML content from the .publishsettings file]
```

## 4. Deploy

Push code to main branch:
```bash
git add .
git commit -m "Deploy backend"
git push origin main
```

The GitHub Action will automatically deploy to your Function App.

## 5. Verify Deployment

Check: https://demo-rpg-func-l0svei.azurewebsites.net/api/
EOF

echo ""
echo "✅ Backend prepared for GitHub deployment!"
echo ""
echo "📁 Files created:"
echo "  - .gitignore"
echo "  - .github/workflows/deploy-function-app.yml"
echo "  - GITHUB-DEPLOYMENT.md"
echo "  - Updated keyvault_helper.py"
echo ""
echo "🎯 Next steps:"
echo "1. Create GitHub repository"
echo "2. Push this code to GitHub"
echo "3. Configure GitHub secrets (see GITHUB-DEPLOYMENT.md)"
echo "4. Push to main branch to auto-deploy"