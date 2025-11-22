# GitHub Actions Secrets Configuration

This document lists all the secrets that need to be configured in your GitHub repository for the CI/CD workflows to function properly.

## Required GitHub Secrets

Navigate to: **Settings → Secrets and variables → Actions → New repository secret**

### 1. Azure Service Principal Credentials

Create an Azure Service Principal with Contributor access:

```bash
az ad sp create-for-rbac \
  --name "github-actions-rpg-app" \
  --role contributor \
  --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID> \
  --sdk-auth
```

#### `AZURE_CREDENTIALS`
**Format:** JSON object from the above command
```json
{
  "clientId": "<GUID>",
  "clientSecret": "<GUID>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

#### `AZURE_CLIENT_ID`
**Value:** The `clientId` from AZURE_CREDENTIALS
**Usage:** Terraform authentication

#### `AZURE_CLIENT_SECRET`
**Value:** The `clientSecret` from AZURE_CREDENTIALS
**Usage:** Terraform authentication

#### `AZURE_SUBSCRIPTION_ID`
**Value:** Your Azure Subscription ID
**Usage:** Terraform authentication

#### `AZURE_TENANT_ID`
**Value:** Your Azure AD Tenant ID
**Usage:** Terraform authentication

### 2. Azure Static Web Apps Deployment Token

#### `AZURE_STATIC_WEB_APPS_API_TOKEN`
**How to get:**
1. After running Terraform, go to Azure Portal
2. Navigate to your Static Web App resource
3. Go to **Overview** → **Manage deployment token**
4. Copy the token

**Alternative:** Get from Terraform output:
```bash
cd infra
terraform output -raw static_web_app_deployment_token
```

## Quick Setup Commands

### Step 1: Create Service Principal
```bash
# Set your subscription
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"

# Create service principal and save output
az ad sp create-for-rbac \
  --name "github-actions-rpg-app" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth > azure-credentials.json

# Extract individual values
CLIENT_ID=$(cat azure-credentials.json | jq -r '.clientId')
CLIENT_SECRET=$(cat azure-credentials.json | jq -r '.clientSecret')
SUBSCRIPTION_ID=$(cat azure-credentials.json | jq -r '.subscriptionId')
TENANT_ID=$(cat azure-credentials.json | jq -r '.tenantId')

echo "AZURE_CREDENTIALS=$(cat azure-credentials.json)"
echo "AZURE_CLIENT_ID=$CLIENT_ID"
echo "AZURE_CLIENT_SECRET=$CLIENT_SECRET"
echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"

# Clean up sensitive file
rm azure-credentials.json
```

### Step 2: Configure GitHub Secrets via CLI

Install GitHub CLI if not already installed:
```bash
# Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

Set the secrets:
```bash
# Login to GitHub
gh auth login

# Set Azure credentials (replace values from Step 1)
gh secret set AZURE_CREDENTIALS < azure-credentials.json
gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
gh secret set AZURE_CLIENT_SECRET --body "$CLIENT_SECRET"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"

# After Terraform deployment, set Static Web App token
gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --body "$(cd infra && terraform output -raw static_web_app_deployment_token)"
```

### Step 3: Verify Secrets
```bash
# List all secrets (values are hidden)
gh secret list
```

Expected output:
```
AZURE_CLIENT_ID                  Updated 2024-XX-XX
AZURE_CLIENT_SECRET              Updated 2024-XX-XX
AZURE_CREDENTIALS                Updated 2024-XX-XX
AZURE_STATIC_WEB_APPS_API_TOKEN  Updated 2024-XX-XX
AZURE_SUBSCRIPTION_ID            Updated 2024-XX-XX
AZURE_TENANT_ID                  Updated 2024-XX-XX
```

## Service Principal Permissions

The service principal needs these permissions:

1. **Contributor** role on the subscription (to create resources)
2. **User Access Administrator** (if you need to assign roles within Terraform)

To add User Access Administrator:
```bash
az role assignment create \
  --assignee $CLIENT_ID \
  --role "User Access Administrator" \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

## Security Best Practices

1. **Rotate Secrets Regularly**: Update service principal credentials every 90 days
2. **Minimum Permissions**: Only grant permissions to required resource groups
3. **Monitor Usage**: Check Azure AD sign-in logs for service principal activity
4. **Use Environments**: Configure GitHub environments with required reviewers for production

## Troubleshooting

### Error: "AuthorizationFailed"
- Check service principal has Contributor role
- Verify subscription ID is correct
- Ensure service principal is not expired

### Error: "InvalidAuthenticationToken"
- Regenerate client secret: `az ad sp credential reset --id $CLIENT_ID`
- Update AZURE_CLIENT_SECRET in GitHub secrets

### Static Web App Deployment Token Invalid
- Token expires after 1 year
- Regenerate in Azure Portal → Static Web App → Manage deployment token
- Update GitHub secret

## Manual Setup (Web UI)

If you prefer to set secrets via GitHub web interface:

1. Go to: `https://github.com/<YOUR_ORG>/<YOUR_REPO>/settings/secrets/actions`
2. Click **New repository secret**
3. Add each secret listed above

## Environment-Specific Secrets

For multi-environment deployments (dev/staging/prod):

1. Create GitHub Environments: Settings → Environments
2. Add environment-specific secrets with same names
3. Workflows will use environment-specific values when deployed to that environment

Example: `AZURE_STATIC_WEB_APPS_API_TOKEN_DEV`, `AZURE_STATIC_WEB_APPS_API_TOKEN_PROD`
