# 🚀 Quick Reference Card

## Most Common Commands

### Deploy Everything
```bash
gh workflow run deploy-complete.yml && gh run watch
```

### Configure GitHub Secrets (First Time)
```bash
# 1. Create service principal
az ad sp create-for-rbac --name "github-actions-rpg-app" \
  --role contributor --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth > azure-creds.json

# 2. Set secrets
gh secret set AZURE_CREDENTIALS < azure-creds.json
gh secret set AZURE_CLIENT_ID --body "$(cat azure-creds.json | jq -r '.clientId')"
gh secret set AZURE_CLIENT_SECRET --body "$(cat azure-creds.json | jq -r '.clientSecret')"
gh secret set AZURE_SUBSCRIPTION_ID --body "$(cat azure-creds.json | jq -r '.subscriptionId')"
gh secret set AZURE_TENANT_ID --body "$(cat azure-creds.json | jq -r '.tenantId')"

# 3. After first deployment
cd infra && gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN \
  --body "$(terraform output -raw static_web_app_deployment_token)"
```

### Local Development
```bash
# Backend
cd dev/rpg-backend-python
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
func start

# Frontend
cd dev/rpg-frontend-main
npm install && npm run serve
```

### Manual Deployment
```bash
cd infra
terraform init
terraform apply -var-file="environments/dev.tfvars"
cd .. && ./scripts/configure-all.sh
```

### Check Status
```bash
# Workflows
gh run list --limit 5

# Azure resources
cd infra
terraform output function_app_url
terraform output static_web_app_url

# Test API
curl "$(cd infra && terraform output -raw function_app_url)/api/SELECTEVENTS"
```

### View Logs
```bash
# GitHub Actions
gh run view <run-id> --log

# Azure Function App
az functionapp log tail --name $(cd infra && terraform output -raw function_app_name) \
  --resource-group $(cd infra && terraform output -raw resource_group_name)
```

### Troubleshooting
```bash
# Reinitialize Terraform
cd infra && terraform init -reconfigure

# Restart Function App
az functionapp restart --name $(terraform output -raw function_app_name) \
  --resource-group $(terraform output -raw resource_group_name)

# Check workflow errors
gh run list --workflow=deploy-complete.yml
gh run view --log
```

## File Locations

| What | Where |
|------|-------|
| Workflows | `.github/workflows/` |
| Backend code | `dev/rpg-backend-python/` |
| Frontend code | `dev/rpg-frontend-main/` |
| Infrastructure | `infra/` |
| Environment configs | `infra/environments/` |
| Scripts | `scripts/` |
| Documentation | `*.md` files |

## Workflow Files

| File | Purpose | Trigger |
|------|---------|---------|
| `deploy-complete.yml` | Full deployment | Push to main |
| `deploy-infrastructure.yml` | Terraform only | Changes to `infra/**` |
| `deploy-backend.yml` | Backend only | Changes to backend code |
| `deploy-frontend.yml` | Frontend only | Changes to frontend code |

## Environment Variables

### Backend (.env / local.settings.json)
- `KEYVAULT_URL` - Key Vault endpoint
- `AZURE_OPENAI_ENDPOINT` - OpenAI endpoint
- `AZURE_OPENAI_KEY` - API key
- `AZURE_OPENAI_DEPLOYMENT` - Model name (gpt-4o)

### Frontend (.env.production)
- `VUE_APP_API_BASE_URL` - Backend API URL
- `VUE_APP_ENVIRONMENT` - Environment name

## Important URLs

After deployment, get URLs with:
```bash
cd infra
echo "Backend: $(terraform output -raw function_app_url)"
echo "Frontend: $(terraform output -raw static_web_app_url)"
echo "Key Vault: $(terraform output -raw keyvault_url)"
```

## Emergency Commands

### Destroy Everything
```bash
cd infra
terraform destroy -var-file="environments/dev.tfvars"
```

### Reset Terraform State
```bash
cd infra
rm -rf .terraform .terraform.lock.hcl
terraform init -reconfigure
```

### Force Redeploy Backend
```bash
gh workflow run deploy-backend.yml
```

### Force Redeploy Frontend
```bash
gh workflow run deploy-frontend.yml
```

## Documentation Quick Links

- **Setup Guide**: `DEPLOYMENT-SUMMARY.md`
- **Project Overview**: `PROJECT-OVERVIEW.md`
- **Workflow Docs**: `.github/README.md`
- **Secrets Setup**: `.github/SECRETS-SETUP.md`
- **Configuration**: `CONFIG-SETUP.md`

## Support Checklist

When asking for help, include:
- [ ] Workflow run ID (`gh run list`)
- [ ] Error message from logs
- [ ] Environment (dev/staging/prod)
- [ ] What you were trying to do
- [ ] What actually happened
