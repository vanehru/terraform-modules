# RPG AI App Deployment Guide

## 🎮 Complete Deployment to Japan East

This guide deploys the demo-rpg-aiapp (Vue.js frontend + Python backend) to the Azure infrastructure in Japan East region.

## 📋 Prerequisites

1. **Azure CLI logged in** with service principal:
   ```bash
   export ARM_CLIENT_ID="your-service-principal-id"
   export ARM_CLIENT_SECRET="your-service-principal-secret"
   export ARM_SUBSCRIPTION_ID="your-subscription-id"
   export ARM_TENANT_ID="your-tenant-id"
   ```

2. **Required tools installed**:
   - Azure Functions Core Tools (`func`)
   - Node.js and npm
   - Azure Static Web Apps CLI (`swa`)

## 🚀 Deployment Options

### Option 1: Complete Deployment (Recommended)
Deploy everything in one command:
```bash
./deploy-complete.sh
```

### Option 2: Step-by-Step Deployment

1. **Deploy Infrastructure**:
   ```bash
   cd rpg-aiapp-infra
   terraform apply -auto-approve
   cd ..
   ```

2. **Deploy Python Backend**:
   ```bash
   ./deploy-backend.sh
   ```

3. **Deploy Vue.js Frontend**:
   ```bash
   ./deploy-frontend.sh
   ```

## 🏗️ What Gets Deployed

### Infrastructure (Japan East)
- ✅ Function App (Y1 Consumption)
- ✅ Static Web App (Standard tier)
- ✅ Key Vault with private endpoint
- ✅ SQL Database with private endpoint
- ✅ Azure OpenAI (East US)
- ✅ VNet with 6 subnets

### Applications
- ✅ **Backend**: Python Function App with 8 API endpoints
- ✅ **Frontend**: Vue.js SPA with RPG game interface
- ✅ **Integration**: Key Vault secrets for all connections

## 🔗 API Endpoints

After deployment, your Function App will have:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/OpenAI` | POST | MBTI personality scoring |
| `/api/SELECTPLAYER` | GET/POST | Get player data |
| `/api/SELECTALLPLAYER` | GET/POST | Get all players |
| `/api/SELECTEVENTS` | GET/POST | Get event data |
| `/api/UPDATE` | POST | Update player data |
| `/api/INSERTUSER` | POST | Register new user |
| `/api/INSERTPLAYER` | POST | Initialize player |
| `/api/LOGIN` | POST | User authentication |

## 🔐 Security Features

- **Key Vault Integration**: All secrets stored securely
- **Managed Identity**: Function App accesses Key Vault without credentials
- **Private Endpoints**: Database and Key Vault isolated from internet
- **Password Hashing**: PBKDF2 for user passwords
- **Input Validation**: All API endpoints validate input

## 💰 Estimated Costs

- **Function App**: ~$0-20/month (Y1 Consumption)
- **Static Web App**: ~$9/month (Standard)
- **SQL Database**: ~$5/month (Basic, 2GB)
- **Key Vault**: ~$1/month
- **OpenAI**: Pay-per-use
- **Total**: ~$15-35/month

## 🎯 Next Steps After Deployment

1. **Add OpenAI Models**: Deploy gpt-4 or gpt-35-turbo to OpenAI service
2. **Database Setup**: Create tables in SQL Database
3. **Frontend Customization**: Modify Vue.js components
4. **CI/CD**: Set up GitHub Actions for automated deployments

## 🔧 Troubleshooting

### Function App Issues
```bash
# Check Function App logs
func azure functionapp logstream <function-app-name>

# Test locally
cd demo-rpg-aiapp/dev/rpg-backend-python
func start
```

### Static Web App Issues
```bash
# Check deployment status
az staticwebapp show --name <app-name> --resource-group <rg-name>

# Redeploy
cd demo-rpg-aiapp/dev/rpg-frontend-main
npm run build
swa deploy
```

### Key Vault Access Issues
- Ensure Function App Managed Identity has proper permissions
- Check if your IP is allowed in Key Vault firewall
- Verify Key Vault URI in Function App settings

## 📞 Support

For issues:
1. Check Azure Portal for resource status
2. Review Function App Application Insights
3. Verify all environment variables are set correctly