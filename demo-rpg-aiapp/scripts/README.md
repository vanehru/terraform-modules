# Configuration Scripts

Automated scripts to configure the RPG application after Terraform infrastructure deployment.

---

## Scripts Overview

### 1. `configure-all.sh` (Recommended)
**Full automation script that configures both backend and frontend**

```bash
./scripts/configure-all.sh
```

**What it does:**
- Fetches all Terraform outputs (Key Vault URL, Function App name, etc.)
- Configures Azure Function App settings
- Updates frontend `.env.production` file
- Updates backend `local.settings.json.example` with actual values
- Optionally builds the frontend

**When to use:** After initial Terraform deployment or when infrastructure changes

---

### 2. `configure-backend.sh`
**Backend-only configuration**

```bash
./scripts/configure-backend.sh
```

**What it does:**
- Configures Azure Function App application settings
- Sets Key Vault URL
- Sets OpenAI endpoint and Key Vault reference

**When to use:** When only backend configuration needs updating

---

### 3. `configure-frontend.sh`
**Frontend-only configuration**

```bash
./scripts/configure-frontend.sh
```

**What it does:**
- Updates `.env.production` with Function App URL
- Optionally builds the frontend

**When to use:** When only frontend API URL needs updating

---

## Prerequisites

### Required Tools
- Azure CLI (`az`) installed and logged in
- Terraform outputs available (run `terraform apply` first)
- Node.js and npm (for frontend build)

### Required Permissions
- Access to the Azure subscription
- Permissions to modify Function App settings
- Terraform state access

---

## Usage Workflow

### Initial Setup (After Terraform Deployment)

1. **Deploy Infrastructure:**
   ```bash
   cd rpg-aiapp-infra
   terraform init
   terraform plan
   terraform apply
   ```

2. **Run Configuration Script:**
   ```bash
   cd ..
   ./scripts/configure-all.sh
   ```

3. **Set up local development (Backend):**
   ```bash
   cd demo-rpg-aiapp/dev/rpg-backend-python
   cp local.settings.json.example local.settings.json
   # Edit local.settings.json if needed for local dev
   ```

4. **Set up local development (Frontend):**
   ```bash
   cd demo-rpg-aiapp/dev/rpg-frontend-main
   cp .env.example .env.local
   # Edit .env.local with http://localhost:7071/api for local backend
   ```

---

## Manual Configuration (If Scripts Fail)

### Backend Manual Steps

```bash
# Get Terraform outputs
cd rpg-aiapp-infra
terraform output

# Set Function App settings
az functionapp config appsettings set \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --settings \
    KEYVAULT_URL=<keyvault-url> \
    AZURE_OPENAI_ENDPOINT=<openai-endpoint> \
    AZURE_OPENAI_KEY="@Microsoft.KeyVault(SecretUri=<keyvault-url>secrets/openai-key/)" \
    AZURE_OPENAI_DEPLOYMENT=gpt-4o
```

### Frontend Manual Steps

```bash
# Edit .env.production manually
cd demo-rpg-aiapp/dev/rpg-frontend-main
cat > .env.production <<EOF
VUE_APP_API_BASE_URL=https://<function-app-name>.azurewebsites.net/api
VUE_APP_ENVIRONMENT=production
EOF

# Build frontend
npm run build
```

---

## Environment Variables Reference

### Backend (Azure Function App)

| Variable | Description | Example |
|----------|-------------|---------|
| `KEYVAULT_URL` | Azure Key Vault URL | `https://my-kv.vault.azure.net/` |
| `AZURE_OPENAI_ENDPOINT` | OpenAI resource endpoint | `https://my-openai.openai.azure.com/` |
| `AZURE_OPENAI_KEY` | OpenAI API key (Key Vault ref) | `@Microsoft.KeyVault(...)` |
| `AZURE_OPENAI_DEPLOYMENT` | OpenAI deployment name | `gpt-4o` |

### Frontend (Vue.js)

| Variable | Description | Example |
|----------|-------------|---------|
| `VUE_APP_API_BASE_URL` | Backend API base URL | `https://my-func.azurewebsites.net/api` |
| `VUE_APP_ENVIRONMENT` | Environment name | `production` |

---

## Troubleshooting

### Script Errors

**Error: "Could not retrieve Terraform outputs"**
```bash
# Solution: Ensure you're in the right directory and Terraform is applied
cd rpg-aiapp-infra
terraform output
```

**Error: "az command not found"**
```bash
# Solution: Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
```

**Error: "Permission denied"**
```bash
# Solution: Make scripts executable
chmod +x scripts/*.sh
```

### Configuration Verification

**Check Backend Settings:**
```bash
az functionapp config appsettings list \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --output table
```

**Check Frontend Config:**
```bash
cat demo-rpg-aiapp/dev/rpg-frontend-main/.env.production
```

**Test Backend:**
```bash
curl https://<function-app-name>.azurewebsites.net/api/SELECTEVENTS
```

---

## CI/CD Integration

### Azure DevOps Pipeline

```yaml
- stage: Configure
  jobs:
  - job: ConfigureApps
    steps:
    - task: AzureCLI@2
      inputs:
        azureSubscription: 'your-subscription'
        scriptType: 'bash'
        scriptLocation: 'scriptPath'
        scriptPath: 'scripts/configure-all.sh'
```

### GitHub Actions

```yaml
- name: Configure Applications
  run: |
    cd demo-rpg-aiapp
    ./scripts/configure-all.sh
  env:
    ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
    ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
    ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
    ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
```

---

## Best Practices

1. **Always run scripts from the project root:**
   ```bash
   cd /path/to/demo-rpg-aiapp
   ./scripts/configure-all.sh
   ```

2. **Review changes before committing:**
   - Check `.env.production.template` (should be committed)
   - Don't commit `.env.production` (gitignored)
   - Don't commit `local.settings.json` (gitignored)

3. **Keep templates updated:**
   - Scripts automatically update `local.settings.json.example`
   - Templates serve as documentation

4. **Secure secrets:**
   - Use Key Vault references in Function App
   - Never commit actual secrets
   - Use Managed Identity when possible

---

## Quick Reference

```bash
# Full configuration
./scripts/configure-all.sh

# Backend only
./scripts/configure-backend.sh

# Frontend only  
./scripts/configure-frontend.sh

# View current config
terraform output  # In rpg-aiapp-infra/
cat demo-rpg-aiapp/dev/rpg-frontend-main/.env.production

# Reset to template
cp demo-rpg-aiapp/dev/rpg-frontend-main/.env.production.template \
   demo-rpg-aiapp/dev/rpg-frontend-main/.env.production
```
