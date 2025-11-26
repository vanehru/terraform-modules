# 🔍 How to Find Your Static Web App in Azure Portal

## 📋 Your Static Web App Details

**Name**: `rpg-gaming-web`
**URL**: https://polite-sea-0d4324500.3.azurestaticapps.net
**Resource Group**: `rpg-aiapp-rg`
**Region**: East Asia

## 🎯 Find in Azure Portal

### Method 1: Direct Search
1. Go to [Azure Portal](https://portal.azure.com)
2. In the top search bar, type: `rpg-gaming-web`
3. Click on the Static Web App result

### Method 2: Resource Group
1. Go to [Azure Portal](https://portal.azure.com)
2. Search for "Resource groups"
3. Click on `rpg-aiapp-rg`
4. Look for `rpg-gaming-web` (Type: Static Web App)

### Method 3: All Resources
1. Go to [Azure Portal](https://portal.azure.com)
2. Click "All resources" in the left menu
3. Filter by Resource group: `rpg-aiapp-rg`
4. Find `rpg-gaming-web`

## 🚀 Deploy Your Frontend

Once you find the Static Web App:

1. **Click on `rpg-gaming-web`**
2. **Go to "Deployment" → "GitHub Actions"** or **"Deployment Center"**
3. **Upload your built files**:
   - Use the ZIP file: `frontend-build.zip`
   - Or connect to GitHub repository

## 📁 Files to Deploy

After running `./deploy-frontend-manual.sh`, you'll have:
- **Built files**: `demo-rpg-aiapp/dev/rpg-frontend-main/dist/`
- **ZIP file**: `demo-rpg-aiapp/dev/rpg-frontend-main/frontend-build.zip`

## 🔗 Quick Links

- **Static Web App URL**: https://polite-sea-0d4324500.3.azurestaticapps.net
- **Azure Portal**: https://portal.azure.com
- **Resource Group**: Search for `rpg-aiapp-rg`

## ✅ Verification

After deployment, your app should be accessible at:
**https://polite-sea-0d4324500.3.azurestaticapps.net**