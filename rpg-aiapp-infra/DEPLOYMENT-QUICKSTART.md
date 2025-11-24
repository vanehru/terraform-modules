# 🚀 RPG Gaming App - Deployment Quick Start

## Overview

This guide gets you from zero to deployed in **~15 minutes** using Azure Cloud Shell.

## ⚡ Quick Deploy (3 Steps)

### Step 1: Deploy Infrastructure (5 minutes)

```bash
# Login and navigate
az login
cd rpg-aiapp-infra

# Deploy
terraform init
terraform apply -auto-approve

# Save outputs
terraform output > deployment-info.txt
```

### Step 2: Configure Cloud Shell (3 minutes)

```bash
# Open https://shell.azure.com (Bash)

# Set variables (update with your values)
RG_NAME="example-rg"
VNET_NAME="example-vnet"
SUBNET_NAME="deployment-subnet"

# Connect Cloud Shell to VNet
az cloud-shell configure \
  --relay-resource-group $RG_NAME \
  --relay-vnet $VNET_NAME \
  --relay-subnet $SUBNET_NAME

# Wait 2-3 minutes for container to start
```

### Step 3: Deploy Code (7 minutes)

```bash
# Clone your code
git clone https://github.com/your-org/rpg-gaming-app.git
cd rpg-gaming-app

# Deploy Function App
cd function-app
func azure functionapp publish example-func --python

# Deploy Static Web App
cd ../frontend
npm run build
swa deploy --app-name rpg-gaming-web --env production
```

## ✅ Verification

```bash
# Test Function App
curl https://example-func.azurewebsites.net/api/health

# Get Static Web App URL
az staticwebapp show \
  --name rpg-gaming-web \
  --resource-group example-rg \
  --query defaultHostname -o tsv
```

## 💰 Cost Breakdown

| Service | Monthly Cost | Notes |
|---------|--------------|-------|
| Static Web App | $0-9 | Free tier available |
| Function App | $0-13 | Consumption plan |
| SQL Database | $5-25 | Basic tier |
| Key Vault | $0-3 | Operations-based |
| OpenAI | Variable | Pay-per-token |
| Storage Account | $1-5 | Minimal usage |
| VNet | $0 | Free |
| Cloud Shell Container | **$5** | **Only infrastructure cost!** |
| **Total** | **~$30-60/month** | vs $230+ with Bastion+VM |

## 🔒 What's Protected?

All backend services use **private endpoints** (no internet access):
- ✅ Key Vault → 10.0.3.x
- ✅ SQL Database → 10.0.4.x
- ✅ Azure OpenAI → 10.0.5.x
- ✅ Storage Account → 10.0.2.x

Only public service:
- 🌐 Static Web App (frontend CDN)

## 📋 Prerequisites

- Azure subscription
- Terraform 1.5+
- Azure CLI 2.50+
- Git

## 🛠️ Optional: One-Line Deployment Script

```bash
cat > deploy-all.sh <<'EOF'
#!/bin/bash
set -e
echo "🚀 Deploying RPG Gaming App..."
cd rpg-aiapp-infra && terraform init && terraform apply -auto-approve
echo "✅ Infrastructure deployed!"
echo "📝 Now configure Cloud Shell: https://shell.azure.com"
echo "   Run: az cloud-shell configure --relay-resource-group example-rg --relay-vnet example-vnet --relay-subnet deployment-subnet"
EOF

chmod +x deploy-all.sh
./deploy-all.sh
```

## 🔧 Troubleshooting

### Cloud Shell can't reach private endpoints

```bash
# Verify DNS resolves to private IPs
nslookup examplekv123.vault.azure.net
# Should return 10.0.3.x (not public IP)

# Restart container if needed
az container restart \
  --name cloudshell-relay \
  --resource-group example-rg
```

### Function App deployment fails

```bash
# Check Function App status
az functionapp show \
  --name example-func \
  --resource-group example-rg \
  --query state

# Restart if needed
az functionapp restart \
  --name example-func \
  --resource-group example-rg
```

## 📚 Full Documentation

- **README.md** - Architecture overview
- **ARCHITECTURE.md** - Detailed technical docs
- **This file** - Quick deployment guide

## 🎯 Architecture Summary

```
Internet → Static Web App (Public)
              ↓
       Function App (VNet)
              ↓
    ┌─────────┼─────────┐
    ↓         ↓         ↓
Key Vault   SQL DB   OpenAI
(Private) (Private) (Private)
```

## 🚀 What Makes This Special?

1. **Cost-Optimized**: $5/month deployment vs $200/month with Bastion
2. **Secure**: Full private endpoint isolation
3. **Fast**: 15-minute deployment
4. **Managed**: No VMs to patch or maintain
5. **Scalable**: Production-ready architecture

## 💡 Pro Tips

1. Use `tmux` in Cloud Shell to persist sessions
2. Create deployment scripts for repeated deployments
3. Monitor costs with Azure Cost Management
4. Enable Application Insights for monitoring
5. Use Azure DevOps for CI/CD pipelines

## Next Steps

1. ✅ Deploy infrastructure
2. ✅ Configure Cloud Shell
3. ✅ Deploy application code
4. 📊 Enable monitoring (Application Insights)
5. 🔄 Set up CI/CD (Azure DevOps/GitHub Actions)
6. 🎮 Customize for your game!
