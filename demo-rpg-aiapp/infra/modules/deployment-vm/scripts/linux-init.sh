#!/bin/bash
# Initialization script for Linux deployment VM

set -e

echo "Starting deployment VM initialization..."

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker azureadmin

# Install Git
sudo apt-get install -y git

# Install Node.js (for Static Web App and Function App deployments)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Python 3.11 (for Function App)
sudo apt-get install -y python3.11 python3.11-venv python3-pip

# Install .NET SDK (for Function App)
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0

# Install Azure Functions Core Tools
sudo npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Install Static Web Apps CLI
sudo npm install -g @azure/static-web-apps-cli

# Install Terraform (optional, for infrastructure updates)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform

# Install useful tools
sudo apt-get install -y jq vim nano htop net-tools

# Login to Azure using managed identity (will be available after VM starts)
# This will be executed manually or via automation

# Create workspace directory
mkdir -p /home/azureadmin/workspace
chown azureadmin:azureadmin /home/azureadmin/workspace

# Create deployment scripts directory
mkdir -p /home/azureadmin/scripts
cat > /home/azureadmin/scripts/deploy-function.sh <<'EOF'
#!/bin/bash
# Deploy Function App from local code

FUNCTION_APP_NAME=$1
RESOURCE_GROUP=$2

if [ -z "$FUNCTION_APP_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
    echo "Usage: $0 <function-app-name> <resource-group>"
    exit 1
fi

echo "Deploying to Function App: $FUNCTION_APP_NAME"

# Navigate to function app code directory
cd /home/azureadmin/workspace/function-app

# Install dependencies
pip install -r requirements.txt

# Deploy using Azure CLI
func azure functionapp publish $FUNCTION_APP_NAME --python

echo "Deployment complete!"
EOF

chmod +x /home/azureadmin/scripts/deploy-function.sh

# Create connection test script
cat > /home/azureadmin/scripts/test-connectivity.sh <<'EOF'
#!/bin/bash
# Test connectivity to private endpoints

echo "Testing connectivity to private endpoints..."

# Test Storage Account
echo -n "Storage Account: "
nc -zv examplestoracc123.blob.core.windows.net 443 2>&1 | grep -q succeeded && echo "✓ Connected" || echo "✗ Failed"

# Test Key Vault
echo -n "Key Vault: "
nc -zv examplekv123.vault.azure.net 443 2>&1 | grep -q succeeded && echo "✓ Connected" || echo "✗ Failed"

# Test SQL Database
echo -n "SQL Database: "
nc -zv rpg-gaming-sql-server.database.windows.net 1433 2>&1 | grep -q succeeded && echo "✓ Connected" || echo "✗ Failed"

# Test OpenAI
echo -n "OpenAI: "
nc -zv rpg-gaming-openai.openai.azure.com 443 2>&1 | grep -q succeeded && echo "✓ Connected" || echo "✗ Failed"

# Test Function App
echo -n "Function App: "
nc -zv example-func.azurewebsites.net 443 2>&1 | grep -q succeeded && echo "✓ Connected" || echo "✗ Failed"

echo "Connectivity test complete!"
EOF

chmod +x /home/azureadmin/scripts/test-connectivity.sh
chown -R azureadmin:azureadmin /home/azureadmin/scripts

# Create README for the VM
cat > /home/azureadmin/README.md <<'EOF'
# Deployment VM Setup

This VM is configured as a deployment/build agent for the RPG Gaming App infrastructure.

## Installed Tools

- Azure CLI
- Docker
- Git
- Node.js 20
- Python 3.11
- .NET SDK 8.0
- Azure Functions Core Tools
- Static Web Apps CLI
- Terraform

## Usage

### Login to Azure
```bash
az login --identity
az account set --subscription <subscription-id>
```

### Deploy Function App
```bash
cd ~/workspace
git clone <your-repo>
cd <your-repo>
~/scripts/deploy-function.sh <function-app-name> <resource-group>
```

### Test Connectivity
```bash
~/scripts/test-connectivity.sh
```

### Deploy Static Web App
```bash
cd ~/workspace/static-web-app
swa deploy --app-name <static-web-app-name>
```

## Network Access

This VM has access to:
- All private endpoints (Storage, Key Vault, SQL, OpenAI)
- Function App (via private network)
- Internet (for downloading packages and tools)

## Security

- VM uses system-assigned managed identity
- No public IP (access via Azure Bastion recommended)
- NSG restricts inbound traffic
EOF

chown azureadmin:azureadmin /home/azureadmin/README.md

echo "Deployment VM initialization complete!"
echo "VM is ready to use for deployments."
