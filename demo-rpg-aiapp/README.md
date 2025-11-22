# RPG AI Application - Complete Project

This is a full-stack Azure-based RPG AI application with automated CI/CD deployment.

## 📁 Project Structure

```
demo-rpg-aiapp/
├── .github/
│   ├── workflows/              # GitHub Actions CI/CD pipelines
│   │   ├── deploy-complete.yml      # Full deployment pipeline ⭐
│   │   ├── deploy-infrastructure.yml # Infrastructure only
│   │   ├── deploy-backend.yml       # Backend only
│   │   └── deploy-frontend.yml      # Frontend only
│   ├── README.md              # Workflow documentation
│   └── SECRETS-SETUP.md       # GitHub secrets configuration guide
├── dev/
│   ├── rpg-backend-python/    # Azure Functions backend (Python)
│   └── rpg-frontend-main/     # Vue.js frontend
├── infra/                     # Terraform infrastructure
│   ├── modules/               # Terraform modules
│   ├── environments/          # Environment-specific configs
│   │   ├── dev.tfvars
│   │   ├── staging.tfvars
│   │   └── prod.tfvars
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── providers.tf
├── scripts/                   # Automation scripts
│   ├── configure-all.sh       # Complete configuration
│   ├── configure-backend.sh   # Backend configuration
│   └── configure-frontend.sh  # Frontend configuration
├── githooks/                  # Git hooks for code quality
│   └── pre-commit
└── GITHUB-SECRETS.md         # Secrets documentation
```

## 🚀 Quick Start

### Prerequisites

- Azure CLI (`az`)
- Terraform >= 1.6.0
- Node.js >= 18
- Python >= 3.11
- Git
- GitHub account with Actions enabled

### 1. Initial Setup

```bash
# Clone repository
git clone <repository-url>
cd demo-rpg-aiapp

# Configure Azure
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"

# Configure GitHub secrets (see .github/SECRETS-SETUP.md)
gh auth login
gh secret set AZURE_CREDENTIALS < azure-creds.json
# ... (see SECRETS-SETUP.md for all secrets)
```

### 2. Deploy Infrastructure

**Option A: Using GitHub Actions (Recommended)**
```bash
# Push to main branch triggers automatic deployment
git push origin main

# Or manually trigger workflow
gh workflow run deploy-complete.yml
```

**Option B: Local Deployment**
```bash
# Deploy infrastructure
cd infra
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Configure applications
cd ..
./scripts/configure-all.sh
```

### 3. Verify Deployment

```bash
# Check workflow status
gh run watch

# Test backend API
FUNCTION_URL=$(cd infra && terraform output -raw function_app_url)
curl "$FUNCTION_URL/api/SELECTEVENTS"

# Get frontend URL
cd infra && terraform output static_web_app_url
```

## 🏗️ Architecture

### Azure Resources

- **Azure Functions** - Python backend API
- **Static Web App** - Vue.js frontend
- **SQL Database** - Data persistence
- **Key Vault** - Secrets management
- **Azure OpenAI** - GPT-4o integration
- **Storage Account** - Function App storage

### Application Flow

```
User → Static Web App (Vue.js)
  ↓
  → Function App API (Python)
    ↓
    ├→ SQL Database (User/Player data)
    ├→ Azure OpenAI (AI interactions)
    └→ Key Vault (Secrets)
```

## 🔄 CI/CD Workflows

### Complete Deployment (`deploy-complete.yml`)

Deploys entire stack in order:
1. Infrastructure (Terraform)
2. Backend (Azure Functions)
3. Frontend (Static Web App)
4. Verification tests

**Triggers:** Push to main, manual dispatch

### Individual Workflows

- `deploy-infrastructure.yml` - Infrastructure only
- `deploy-backend.yml` - Backend only (depends on infrastructure)
- `deploy-frontend.yml` - Frontend only (depends on backend)

**Triggers:** File changes, manual dispatch, repository events

## 📝 Configuration Management

### Environment Variables

**Backend** (`.env` / `local.settings.json`):
- `KEYVAULT_URL` - Key Vault endpoint
- `AZURE_OPENAI_ENDPOINT` - OpenAI service endpoint
- `AZURE_OPENAI_KEY` - API key (from Key Vault)
- `AZURE_OPENAI_DEPLOYMENT` - Model deployment name

**Frontend** (`.env.production`):
- `VUE_APP_API_BASE_URL` - Backend API URL
- `VUE_APP_ENVIRONMENT` - Environment name

### Configuration Scripts

```bash
# Configure everything after Terraform deployment
./scripts/configure-all.sh

# Backend only
./scripts/configure-backend.sh

# Frontend only
./scripts/configure-frontend.sh
```

## 🔐 Security

### Secrets Management

1. **GitHub Secrets** - Service principal credentials
2. **Azure Key Vault** - Application secrets
3. **Managed Identity** - Function App authentication
4. **Key Vault References** - Automatic secret injection

### Best Practices

✅ No secrets in code  
✅ Key Vault references in Function App  
✅ Managed Identity for Azure resources  
✅ HTTPS enforced everywhere  
✅ CORS configured properly  
✅ SQL connection strings in Key Vault  

## 🧪 Development Workflow

### Local Development

```bash
# Backend
cd dev/rpg-backend-python
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
func start

# Frontend
cd dev/rpg-frontend-main
npm install
npm run serve
```

### Making Changes

```bash
# 1. Create feature branch
git checkout -b feature/your-feature

# 2. Make changes
# Edit files...

# 3. Test locally
npm run build  # Frontend
func start     # Backend

# 4. Commit and push
git add .
git commit -m "Add feature"
git push origin feature/your-feature

# 5. Create PR
gh pr create

# 6. After approval, merge to main
# This triggers automatic deployment
```

## 🌍 Multi-Environment Deployment

### Environment Files

- `infra/environments/dev.tfvars` - Development
- `infra/environments/staging.tfvars` - Staging
- `infra/environments/prod.tfvars` - Production

### Deploy to Specific Environment

```bash
# Via GitHub Actions
gh workflow run deploy-complete.yml -f environment=prod

# Via Terraform
cd infra
terraform workspace select prod
terraform apply -var-file="environments/prod.tfvars"
```

## 📊 Monitoring and Logs

### View Logs

```bash
# Function App logs
az functionapp log tail --name <app-name> --resource-group <rg-name>

# GitHub Actions logs
gh run list
gh run view <run-id> --log

# Azure Portal
# Navigate to Function App → Monitoring → Logs
```

### Metrics

- Function App - Requests, errors, response time
- Static Web App - Bandwidth, requests
- SQL Database - DTU usage, connections
- OpenAI - Token usage, API calls

## 🐛 Troubleshooting

### Common Issues

**Infrastructure deployment fails:**
```bash
# Check Terraform state
cd infra
terraform refresh
terraform plan

# Check Azure permissions
az role assignment list --assignee <service-principal-id>
```

**Backend deployment fails:**
```bash
# Check Function App status
az functionapp show --name <app-name> --resource-group <rg-name>

# Restart Function App
az functionapp restart --name <app-name> --resource-group <rg-name>

# Check logs
az functionapp log tail --name <app-name> --resource-group <rg-name>
```

**Frontend not updating:**
```bash
# Clear Static Web App cache
# Redeploy via workflow
gh workflow run deploy-frontend.yml

# Check build logs in Actions
gh run list --workflow=deploy-frontend.yml
```

### Debug Mode

```bash
# Enable verbose logging in workflows
# Add to workflow file:
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## 📚 Documentation

- [GitHub Actions Workflows](.github/README.md) - CI/CD pipeline details
- [Secrets Setup](.github/SECRETS-SETUP.md) - GitHub secrets configuration
- [Architecture](infra/ARCHITECTURE.md) - Infrastructure design
- [Network Diagram](infra/DIAGRAM.md) - Network topology
- [Deployment Guide](infra/DEPLOYMENT-QUICKSTART.md) - Step-by-step deployment
- [Configuration Guide](CONFIG-SETUP.md) - Environment configuration
- [Backend README](dev/rpg-backend-python/README.md) - Backend documentation
- [Frontend README](dev/rpg-frontend-main/README.md) - Frontend documentation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linter
5. Submit a pull request

### Code Quality

```bash
# Backend
cd dev/rpg-backend-python
pylint *.py

# Frontend
cd dev/rpg-frontend-main
npm run lint
npm run test:unit
```

## 📦 Dependencies

### Backend
- `azure-functions`
- `azure-identity`
- `azure-keyvault-secrets`
- `openai`
- `pyodbc`
- `passlib`

### Frontend
- `vue` 2.6
- `vuetify` 2.6
- `vue-router` 3.5
- `vuex` 3.6
- `axios` 1.11
- `ityped` 1.0

### Infrastructure
- Terraform >= 1.6.0
- Azure Provider >= 3.0

## 🔄 Maintenance

### Regular Tasks

- [ ] Update dependencies monthly
- [ ] Rotate service principal credentials every 90 days
- [ ] Review and update Key Vault secrets
- [ ] Check for Terraform provider updates
- [ ] Monitor Azure costs
- [ ] Review application logs for errors

### Backup

```bash
# Backup Terraform state
cd infra
terraform state pull > backup-$(date +%Y%m%d).tfstate

# Backup SQL Database
az sql db export --name <db-name> --resource-group <rg-name> \
  --server <server-name> --admin-user <user> --admin-password <pass> \
  --storage-key <key> --storage-key-type StorageAccessKey \
  --storage-uri "https://<account>.blob.core.windows.net/<container>/backup.bacpac"
```

## 📞 Support

For issues, questions, or contributions:
- GitHub Issues: Create an issue in this repository
- Pull Requests: Submit PRs for bug fixes or features
- Documentation: Check docs in each module folder

## 📄 License

[Specify your license here]

## 🎯 Roadmap

- [ ] Add automated testing in CI/CD
- [ ] Implement blue-green deployments
- [ ] Add performance monitoring
- [ ] Create disaster recovery plan
- [ ] Add multi-region support
- [ ] Implement feature flags
