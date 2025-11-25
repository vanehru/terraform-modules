# Manual Deployment Guide

Since Azure authentication isn't available in this VM, here are alternative deployment methods:

## 🏗️ Build Frontend

```bash
./deploy-frontend-manual.sh
```

This will:
- ✅ Build the Vue.js frontend
- ✅ Configure API endpoints
- ✅ Create deployment ZIP
- ✅ Show deployment options

## 🚀 Deployment Options

### Option 1: GitHub Integration (Recommended)

1. **Push to GitHub**:
   ```bash
   cd demo-rpg-aiapp/dev/rpg-frontend-main
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/rpg-frontend.git
   git push -u origin main
   ```

2. **Connect Static Web App**:
   - Go to Azure Portal → Static Web Apps
   - Select your app → Deployment → GitHub
   - Connect repository and set build settings:
     - **App location**: `/`
     - **Build location**: `dist`
     - **Build command**: `npm run build`

### Option 2: ZIP Upload via Azure Portal

1. **Get the ZIP file**:
   ```bash
   # After running deploy-frontend-manual.sh
   ls demo-rpg-aiapp/dev/rpg-frontend-main/frontend-build.zip
   ```

2. **Upload via Portal**:
   - Go to Azure Portal → Static Web Apps
   - Select your app → Overview → Browse
   - Use deployment center to upload ZIP

### Option 3: Azure CLI (if available elsewhere)

```bash
# On a machine with Azure CLI access
az staticwebapp deploy \
  --name "your-static-web-app-name" \
  --resource-group "rpg-aiapp-rg" \
  --source ./dist
```

## 🔧 Backend Deployment

The Python backend can still be deployed if Azure Functions Core Tools is available:

```bash
./deploy-backend.sh
```

Or manually via:
- Azure Portal → Function Apps → Deployment Center
- Upload the `rpg-backend-python` folder as ZIP

## 📋 Deployment Status

After running `./deploy-frontend-manual.sh`, you'll get:

- ✅ Built frontend in `dist/` folder
- ✅ Deployment ZIP file
- ✅ Configuration with correct API endpoints
- ✅ Ready for any deployment method above

## 🎯 Next Steps

1. Choose deployment method above
2. Deploy frontend to Static Web App
3. Test the application
4. Configure any additional settings in Azure Portal