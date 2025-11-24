# GitHub Actions CI/CD Pipeline

This directory contains GitHub Actions workflows for automated deployment of the RPG AI Application.

## Workflow Files

### 1. `deploy-complete.yml` - Complete Deployment Pipeline ⭐ RECOMMENDED

**Use this for:** Full stack deployment in correct order

**Triggers:**
- Push to `main` branch
- Manual workflow dispatch

**What it does:**
1. Deploys infrastructure (Terraform)
2. Deploys backend (Python Azure Functions)
3. Deploys frontend (Vue.js Static Web App)
4. Verifies deployment

**Usage:**
```bash
# Automatic: Push to main branch
git push origin main

# Manual: Run via GitHub Actions UI
# Go to Actions → Complete Deployment Pipeline → Run workflow
# Or use GitHub CLI:
gh workflow run deploy-complete.yml
```

### 2. `deploy-infrastructure.yml` - Infrastructure Only

**Use this for:** Terraform infrastructure changes only

**Triggers:**
- Push/PR with changes to `infra/**`
- Manual workflow dispatch

**What it does:**
1. Terraform plan (always runs)
2. Terraform apply (only on main branch)
3. Configures Function App settings
4. Triggers application deployment

### 3. `deploy-backend.yml` - Backend Only

**Use this for:** Backend code changes only

**Triggers:**
- Push with changes to `dev/rpg-backend-python/**`
- Triggered after infrastructure deployment
- Manual workflow dispatch

**What it does:**
1. Installs Python dependencies
2. Creates deployment package
3. Deploys to Azure Functions

### 4. `deploy-frontend.yml` - Frontend Only

**Use this for:** Frontend code changes only

**Triggers:**
- Push with changes to `dev/rpg-frontend-main/**`
- Triggered after infrastructure deployment
- Manual workflow dispatch

**What it does:**
1. Builds Vue.js application
2. Creates production environment file
3. Deploys to Azure Static Web Apps

## Required GitHub Secrets

Before running workflows, configure these secrets (see [SECRETS-SETUP.md](SECRETS-SETUP.md)):

- `AZURE_CREDENTIALS` - Service principal JSON
- `AZURE_CLIENT_ID` - Terraform auth
- `AZURE_CLIENT_SECRET` - Terraform auth
- `AZURE_SUBSCRIPTION_ID` - Azure subscription
- `AZURE_TENANT_ID` - Azure AD tenant
- `AZURE_STATIC_WEB_APPS_API_TOKEN` - Static Web App deployment

## Quick Start

### First-Time Deployment

```bash
# 1. Configure GitHub secrets (see SECRETS-SETUP.md)
gh secret set AZURE_CREDENTIALS < azure-creds.json
# ... (set other secrets)

# 2. Deploy everything
gh workflow run deploy-complete.yml

# 3. Monitor deployment
gh run watch
```

### Subsequent Deployments

**Option A: Automatic (Recommended)**
```bash
# Just push to main - workflows trigger automatically
git add .
git commit -m "Update application"
git push origin main
```

**Option B: Manual Deployment**
```bash
# Deploy specific component
gh workflow run deploy-backend.yml
gh workflow run deploy-frontend.yml

# Or full deployment
gh workflow run deploy-complete.yml
```

## Workflow Dependencies

```
deploy-complete.yml
├── 1. deploy-infrastructure
│   ├── Terraform init/plan/apply
│   └── Output: resource names and URLs
├── 2. deploy-backend (depends on step 1)
│   ├── Input: function_app_name
│   └── Deploys Python code
├── 3. deploy-frontend (depends on step 2)
│   ├── Input: function_app_url
│   └── Deploys Vue.js app
└── 4. verify-deployment
    └── Tests API endpoints
```

## Environment Variables

Workflows automatically configure these from Terraform outputs:

**Backend (.env):**
- `KEYVAULT_URL` - Azure Key Vault URL
- `AZURE_OPENAI_ENDPOINT` - OpenAI endpoint
- `AZURE_OPENAI_KEY` - Retrieved from Key Vault
- `AZURE_OPENAI_DEPLOYMENT` - Model deployment name

**Frontend (.env.production):**
- `VUE_APP_API_BASE_URL` - Backend API URL
- `VUE_APP_ENVIRONMENT` - Environment name

## Monitoring and Logs

### View Workflow Runs
```bash
# List recent runs
gh run list --workflow=deploy-complete.yml

# Watch active run
gh run watch

# View specific run logs
gh run view <RUN_ID> --log
```

### Azure Resources
```bash
# Check Function App logs
az functionapp log tail --name <function-app-name> --resource-group <rg-name>

# Check Function App status
az functionapp show --name <function-app-name> --resource-group <rg-name> --query state
```

## Troubleshooting

### Terraform Apply Fails

**Error:** `Backend configuration changed`
```bash
# Solution: Reinitialize Terraform
cd infra
terraform init -reconfigure
```

**Error:** `Resource already exists`
```bash
# Solution: Import existing resource or rename
terraform import <resource_type>.<name> <azure_resource_id>
```

### Backend Deployment Fails

**Error:** `Package deployment failed`
```bash
# Check function app logs
az functionapp log tail --name <function-app-name> --resource-group <rg-name>

# Restart function app
az functionapp restart --name <function-app-name> --resource-group <rg-name>
```

**Error:** `Module not found: pyodbc`
```bash
# Verify requirements.txt includes all dependencies
# Redeploy backend workflow
```

### Frontend Deployment Fails

**Error:** `Static Web App token invalid`
```bash
# Get new token from Terraform output
cd infra
terraform output -raw static_web_app_deployment_token

# Update GitHub secret
gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --body "<new-token>"
```

**Error:** `Build failed: Module not found`
```bash
# Check node version in workflow (should be 18)
# Verify package.json has all dependencies
```

### Common Issues

**Issue:** Workflow stuck on "Waiting"
- Check if another workflow is running (GitHub limits concurrent runs)
- Check environment protection rules

**Issue:** "No Terraform changes detected"
- Normal if infrastructure unchanged
- Workflow will skip apply and proceed to deployment

**Issue:** "Function App cold start timeout"
- Azure Functions need ~30s to warm up after deployment
- Retry API calls after waiting

## Advanced Configuration

### Multi-Environment Deployment

Create environment-specific variable files:

```bash
# infra/environments/dev.tfvars
environment = "dev"
location = "eastus"

# infra/environments/prod.tfvars
environment = "prod"
location = "eastus"
```

Modify workflow:
```yaml
- name: Terraform Plan
  run: |
    terraform plan \
      -var-file="environments/${{ inputs.environment }}.tfvars" \
      -out=tfplan
```

### Approval Gates

Add protected environments in GitHub:

1. Settings → Environments → New environment
2. Name: `production`
3. Enable "Required reviewers"
4. Add reviewers

Update workflow:
```yaml
deploy-infrastructure:
  environment: production  # Requires approval
```

### Notifications

Add Slack/Teams notifications:

```yaml
- name: Notify Deployment Status
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Performance Optimization

- **Caching:** Node modules and Terraform providers are cached
- **Parallel Jobs:** Independent deployments can run in parallel
- **Conditional Execution:** Workflows only run when relevant files change
- **Artifact Reuse:** Build artifacts stored for 7 days

## Security Best Practices

1. ✅ Service principal has minimum required permissions
2. ✅ Secrets stored in GitHub encrypted secrets
3. ✅ Key Vault references used for sensitive values
4. ✅ No secrets in code or logs
5. ✅ HTTPS enforced for all endpoints
6. ✅ Static Web App authentication configured

## Support

For issues with:
- **Workflows:** Check Actions logs, workflow YAML syntax
- **Terraform:** Check Terraform plan output, Azure permissions
- **Azure Resources:** Check Azure Portal, resource logs
- **GitHub Actions:** Check [GitHub Actions docs](https://docs.github.com/actions)

## Workflow Status Badges

Add to README.md:

```markdown
![Infrastructure](https://github.com/<org>/<repo>/actions/workflows/deploy-infrastructure.yml/badge.svg)
![Backend](https://github.com/<org>/<repo>/actions/workflows/deploy-backend.yml/badge.svg)
![Frontend](https://github.com/<org>/<repo>/actions/workflows/deploy-frontend.yml/badge.svg)
```
