# Backend Deployment Instructions

## 📦 Ready for GitHub Dev Branch

Your Python backend is prepared for deployment via GitHub integration.

## 🚀 Steps to Deploy

### 1. Commit and Push to GitHub

```bash
# Commit the code
git commit -m "Python backend ready for deployment"

# Add your GitHub repository
git remote add origin https://github.com/yourusername/rpg-backend.git

# Push to dev branch
git push -u origin dev
```

### 2. Link Function App to GitHub

1. **Go to Azure Portal** → Function Apps → `demo-rpg-func-l0svei`
2. **Click "Deployment Center"** (left menu)
3. **Select "GitHub"**
4. **Authorize GitHub** and select your repository
5. **Choose branch**: `dev`
6. **Build provider**: GitHub Actions
7. **Click "Save"**

### 3. Auto-Deploy Configuration

The Function App will automatically:
- ✅ Pull code from dev branch
- ✅ Install Python dependencies
- ✅ Deploy all functions
- ✅ Configure Key Vault integration

## 🔧 Function App Settings

These are already configured in your infrastructure:
- `KEY_VAULT_URI`: https://demo-rpgkv123.vault.azure.net/
- `AZURE_OPENAI_DEPLOYMENT`: gpt-4o

## 🎯 API Endpoints

After deployment, your APIs will be available at:
- **Base URL**: https://demo-rpg-func-l0svei.azurewebsites.net/api/
- **OpenAI**: `/api/OpenAI`
- **Login**: `/api/LOGIN`
- **Player Data**: `/api/SELECTPLAYER`
- **All Players**: `/api/SELECTALLPLAYER`
- **Events**: `/api/SELECTEVENTS`
- **Update**: `/api/UPDATE`
- **Register**: `/api/INSERTUSER`
- **Initialize**: `/api/INSERTPLAYER`

## ✅ Verification

Test deployment:
```bash
curl https://demo-rpg-func-l0svei.azurewebsites.net/api/SELECTALLPLAYER
```

Your backend is ready to push to GitHub dev branch!