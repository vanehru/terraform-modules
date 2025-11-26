#!/bin/bash

# Prepare Python Backend for Dev Branch Push
set -e

echo "📦 Preparing Python Backend for Dev Branch..."

# Navigate to backend
cd demo-rpg-aiapp/dev/rpg-backend-python

# Update keyvault helper
echo "⚙️  Updating Key Vault helper..."
cp ../../../keyvault_helper_updated.py keyvault_helper.py

# Create .gitignore
echo "📝 Creating .gitignore..."
cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
*$py.class
local.settings.json
.env
.venv
env/
venv/
.vscode/
.DS_Store
*.log
EOF

# Initialize git if not already done
if [ ! -d ".git" ]; then
  echo "🔧 Initializing git repository..."
  git init
  git branch -M dev
fi

# Add all files
echo "📁 Adding files to git..."
git add .
git status

echo ""
echo "✅ Backend prepared for dev branch!"
echo ""
echo "📋 Files ready:"
echo "  - Updated keyvault_helper.py (with infrastructure secrets)"
echo "  - .gitignore (excludes sensitive files)"
echo "  - All Python function code"
echo ""
echo "🎯 Next steps:"
echo "1. Commit the changes:"
echo "   git commit -m 'Prepare backend for deployment'"
echo ""
echo "2. Add your GitHub remote:"
echo "   git remote add origin https://github.com/yourusername/rpg-backend.git"
echo ""
echo "3. Push to dev branch:"
echo "   git push -u origin dev"
echo ""
echo "4. In Azure Function App, link to GitHub dev branch"
echo "   Function App → Deployment Center → GitHub → Select repo/dev branch"