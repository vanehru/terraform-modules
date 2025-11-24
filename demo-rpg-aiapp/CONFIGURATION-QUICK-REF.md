# Configuration Management - Quick Reference

## 🎯 Problem Solved

**Before:** URLs and secrets hardcoded everywhere, painful to update after deployment  
**After:** One command automatically configures everything from Terraform outputs

---

## 📁 Files Created

### Configuration Templates (✅ Committed to Git)

**Backend:**
```
rpg-backend-python/
├── .env.example                    # Environment variable template
├── local.settings.json.example     # Azure Functions template (auto-updated)
└── .gitignore                      # Protects actual config files
```

**Frontend:**
```
rpg-frontend-main/
├── .env.example                    # Default values
├── .env.development               # Development config
├── .env.production.template       # Production template
├── src/services/api.js            # Centralized API service
└── .gitignore                     # Protects .env.production
```

### Automation Scripts (✅ Executable)

```
scripts/
├── configure-all.sh               # Full automation (RECOMMENDED)
├── configure-backend.sh           # Backend only
├── configure-frontend.sh          # Frontend only
└── README.md                      # Detailed documentation
```

### Documentation

```
demo-rpg-aiapp/
├── CODE-REVIEW-SUMMARY.md         # Complete review summary
├── CONFIG-SETUP.md                # Detailed configuration guide
└── CONFIGURATION-QUICK-REF.md     # This file
```

---

## 🚀 Quick Start

### After Terraform Deployment

```bash
# Step 1: Navigate to project root
cd /path/to/demo-rpg-aiapp

# Step 2: Run configuration script
./scripts/configure-all.sh

# Step 3: Done! 🎉
```

**What happens:**
1. Reads Terraform outputs (Key Vault URL, Function App name, etc.)
2. Updates Azure Function App settings
3. Creates `.env.production` with correct API URL
4. Updates `local.settings.json.example` for local dev
5. Optionally builds frontend

---

## 🔧 Individual Configuration

### Backend Only

```bash
./scripts/configure-backend.sh
```

### Frontend Only

```bash
./scripts/configure-frontend.sh
```

---

## 💻 Local Development Setup

### Backend

```bash
cd rpg-aiapp-dev/rpg-backend-python

# Copy template to actual config
cp local.settings.json.example local.settings.json

# Edit with your local values (optional)
nano local.settings.json

# Start local Functions runtime
func start
```

### Frontend

```bash
cd rpg-aiapp-dev/rpg-frontend-main

# Copy template
cp .env.example .env.local

# Edit to point to local backend
echo "VUE_APP_API_BASE_URL=http://localhost:7071/api" > .env.local

# Start dev server
npm run serve
```

---

## 🔒 Security

### What's Protected

❌ **Never Committed (Gitignored):**
- `local.settings.json` (backend)
- `.env` (backend)
- `.env.local` (frontend)
- `.env.production` (frontend)

✅ **Safely Committed:**
- `.env.example` (templates)
- `.env.production.template` (template)
- `local.settings.json.example` (template)
- All scripts and documentation

### Secrets Management

**Local Development:**
```json
{
  "AZURE_OPENAI_KEY": "actual-key-here"
}
```

**Production (Azure):**
```json
{
  "AZURE_OPENAI_KEY": "@Microsoft.KeyVault(SecretUri=https://vault.azure.net/secrets/key/)"
}
```

---

## 📋 Environment Variables Reference

### Backend (Azure Functions)

| Variable | Example | Where Used |
|----------|---------|------------|
| `KEYVAULT_URL` | `https://kv-name.vault.azure.net/` | All functions |
| `AZURE_OPENAI_ENDPOINT` | `https://openai.openai.azure.com/` | OpenAI function |
| `AZURE_OPENAI_KEY` | Key Vault reference | OpenAI function |
| `AZURE_OPENAI_DEPLOYMENT` | `gpt-4o` | OpenAI function |

### Frontend (Vue.js)

| Variable | Example | Where Used |
|----------|---------|------------|
| `VUE_APP_API_BASE_URL` | `https://func-app.azurewebsites.net/api` | All API calls |
| `VUE_APP_ENVIRONMENT` | `production` | General config |

---

## 🔍 Verification Commands

### Check Backend Configuration

```bash
# View Function App settings
az functionapp config appsettings list \
  --name <function-app-name> \
  --resource-group <resource-group> \
  --output table

# Test endpoint
curl https://<function-app-name>.azurewebsites.net/api/SELECTEVENTS
```

### Check Frontend Configuration

```bash
# View production config
cat rpg-aiapp-dev/rpg-frontend-main/.env.production

# Should show:
# VUE_APP_API_BASE_URL=https://your-func-app.azurewebsites.net/api
```

### Test Local Setup

```bash
# Backend
cd rpg-backend-python
func start  # Should start on http://localhost:7071

# Frontend (new terminal)
cd rpg-frontend-main
npm run serve  # Should start on http://localhost:8080
```

---

## 🐛 Troubleshooting

### Script Fails

**Problem:** "Could not retrieve Terraform outputs"
```bash
# Solution: Verify Terraform is applied
cd rpg-aiapp-infra
terraform output
```

**Problem:** "az: command not found"
```bash
# Solution: Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
```

### Configuration Not Applied

**Backend:**
```bash
# Manually set one setting
az functionapp config appsettings set \
  --name <name> \
  --resource-group <rg> \
  --settings KEYVAULT_URL=<url>
```

**Frontend:**
```bash
# Manually create .env.production
cat > rpg-frontend-main/.env.production <<EOF
VUE_APP_API_BASE_URL=https://your-func.azurewebsites.net/api
EOF

# Rebuild
npm run build
```

---

## 📊 Configuration Flow

```
┌─────────────────┐
│ Terraform Apply │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│ Infrastructure Created      │
│ - Key Vault                 │
│ - Function App              │
│ - Static Web App            │
│ - OpenAI Resource           │
└────────┬────────────────────┘
         │
         ▼
┌────────────────────────────┐
│ Run: configure-all.sh      │
└────────┬───────────────────┘
         │
         ├──────────────────┬─────────────────┐
         ▼                  ▼                 ▼
┌────────────────┐  ┌──────────────┐  ┌─────────────────┐
│ Update Backend │  │ Update       │  │ Update          │
│ Function App   │  │ Frontend     │  │ Templates       │
│ Settings       │  │ .env.prod    │  │ for Local Dev   │
└────────────────┘  └──────────────┘  └─────────────────┘
         │                  │                 │
         └──────────────────┴─────────────────┘
                           │
                           ▼
                  ┌────────────────┐
                  │ Ready to Use! │
                  └────────────────┘
```

---

## ✅ Checklist

After running configuration scripts:

- [ ] Backend Function App settings updated in Azure
- [ ] Frontend `.env.production` created with correct URL
- [ ] Backend `local.settings.json.example` has actual values
- [ ] Test backend endpoint responds
- [ ] Frontend built successfully
- [ ] Test login/signup flow works
- [ ] Verify OpenAI integration works
- [ ] Check all API calls succeed

---

## 📚 Related Documentation

- **[CODE-REVIEW-SUMMARY.md](./CODE-REVIEW-SUMMARY.md)** - Complete code review and fixes
- **[CONFIG-SETUP.md](./CONFIG-SETUP.md)** - Detailed configuration guide
- **[scripts/README.md](./scripts/README.md)** - Script documentation
- **[FIXES.md](./rpg-aiapp-dev/rpg-frontend-main/FIXES.md)** - Frontend specific fixes

---

## 🎓 Best Practices

1. ✅ **Always use scripts** - Don't manually configure
2. ✅ **Commit templates** - Keep `.example` files updated
3. ✅ **Never commit secrets** - Check `.gitignore` is working
4. ✅ **Use Key Vault** - Store secrets in Key Vault, not env vars
5. ✅ **Document changes** - Update templates when infrastructure changes
6. ✅ **Test locally first** - Use local settings before deploying
7. ✅ **Verify configuration** - Always check settings were applied

---

## 🆘 Need Help?

1. Check the detailed guides:
   - [CONFIG-SETUP.md](./CONFIG-SETUP.md)
   - [scripts/README.md](./scripts/README.md)

2. Verify Terraform outputs:
   ```bash
   cd rpg-aiapp-infra
   terraform output
   ```

3. Check Azure resources exist:
   ```bash
   az resource list --resource-group <rg-name> --output table
   ```

4. Test manually if scripts fail (see Troubleshooting section)
