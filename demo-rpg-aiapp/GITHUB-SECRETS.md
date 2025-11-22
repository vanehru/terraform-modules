# GitHub Secrets Configuration

This document describes the required GitHub Secrets for deploying the RPG Gaming App Azure Functions.

## Required Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

### 1. AZURE_OPENAI_ENDPOINT
- **Description**: Azure OpenAI Service endpoint URL
- **Example**: `https://your-openai-resource.openai.azure.com/`
- **How to get**: 
  1. Go to Azure Portal
  2. Navigate to your Azure OpenAI resource
  3. Click on "Keys and Endpoint"
  4. Copy the "Endpoint" value

### 2. AZURE_OPENAI_KEY
- **Description**: Azure OpenAI API Key
- **Example**: `abc123def456...` (32+ characters)
- **How to get**: 
  1. Go to Azure Portal
  2. Navigate to your Azure OpenAI resource
  3. Click on "Keys and Endpoint"
  4. Copy "KEY 1" or "KEY 2"

### 3. KEYVAULT_URL
- **Description**: Azure Key Vault URL for storing SQL connection strings
- **Example**: `https://your-keyvault.vault.azure.net/`
- **How to get**: 
  1. Go to Azure Portal
  2. Navigate to your Key Vault resource
  3. Copy the "Vault URI" from the Overview page

### 4. AZURE_FUNCTIONAPP_PUBLISH_PROFILE
- **Description**: Azure Functions publish profile for deployment
- **How to get**: 
  1. Go to Azure Portal
  2. Navigate to your Function App
  3. Click on "Get publish profile" (download button in toolbar)
  4. Open the downloaded `.PublishSettings` file
  5. Copy the entire XML content

### 5. CONNECTION_STRINGS (Optional)
- **Description**: JSON array of connection strings if not using Key Vault
- **Example**: 
```json
[
  {
    "name": "SqlConnection",
    "value": "Server=tcp:yourserver.database.windows.net,1433;Database=yourdatabase;...",
    "type": "SQLAzure",
    "slotSetting": false
  }
]
```

## Setting Secrets via GitHub CLI

You can also set secrets using the GitHub CLI:

```bash
# Install GitHub CLI if not already installed
# macOS: brew install gh
# Login
gh auth login

# Set secrets
gh secret set AZURE_OPENAI_ENDPOINT --body "https://your-openai-resource.openai.azure.com/"
gh secret set AZURE_OPENAI_KEY --body "your-api-key-here"
gh secret set KEYVAULT_URL --body "https://your-keyvault.vault.azure.net/"
gh secret set AZURE_FUNCTIONAPP_PUBLISH_PROFILE < path/to/publishprofile.PublishSettings
```

## Local Development

For local development, create a `local.settings.json` file (already in .gitignore):

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "AZURE_OPENAI_ENDPOINT": "https://your-openai-resource.openai.azure.com/",
    "AZURE_OPENAI_KEY": "your-api-key-here",
    "KEYVAULT_URL": "https://your-keyvault.vault.azure.net/"
  }
}
```

**NEVER commit `local.settings.json` to git!**

## Security Best Practices

1. ✅ **Use Key Vault**: Store SQL connection strings and other secrets in Azure Key Vault
2. ✅ **Rotate Keys**: Regularly rotate Azure OpenAI keys and other credentials
3. ✅ **Managed Identity**: Configure your Function App to use Managed Identity to access Key Vault
4. ✅ **Least Privilege**: Grant only necessary permissions to service principals
5. ✅ **Monitor Access**: Enable auditing on Key Vault to track secret access
6. ❌ **Never hardcode**: Never hardcode secrets in source code
7. ❌ **Never commit**: Never commit `local.settings.json` or `.env` files

## Managed Identity Setup

To allow your Function App to access Key Vault without storing credentials:

1. **Enable Managed Identity on Function App**:
   ```bash
   az functionapp identity assign \
     --name your-function-app-name \
     --resource-group your-resource-group
   ```

2. **Grant Key Vault Access**:
   ```bash
   az keyvault set-policy \
     --name your-keyvault-name \
     --object-id <managed-identity-object-id> \
     --secret-permissions get list
   ```

3. **Update Function App Settings**:
   ```bash
   az functionapp config appsettings set \
     --name your-function-app-name \
     --resource-group your-resource-group \
     --settings KEYVAULT_URL=https://your-keyvault.vault.azure.net/
   ```

## Verification

After setting secrets, verify your GitHub Actions workflow:

1. Go to your repository on GitHub
2. Click on "Actions" tab
3. Trigger a workflow manually or push a commit
4. Check the workflow run logs for any errors

## Troubleshooting

### Error: "Please set the AZURE_OPENAI_ENDPOINT environment variable"
- Verify the secret name is exactly `AZURE_OPENAI_ENDPOINT` (case-sensitive)
- Check that the workflow is correctly passing the secret to the Function App

### Error: "環境変数 'KEYVAULT_URL' が設定されていません"
- Verify the secret name is exactly `KEYVAULT_URL`
- Ensure the Function App has Managed Identity enabled
- Check Key Vault access policies

### Error: "Unauthorized" when accessing Key Vault
- Verify Managed Identity is assigned to Function App
- Check Key Vault access policies include the Managed Identity
- Ensure the secret name in Key Vault is `sqlconnectionString`
