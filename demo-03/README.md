# Azure Linux VM Terraform Configuration

This Terraform configuration deploys Azure Linux Virtual Machines using a modular approach with **user input-based VM type selection**.

## 🚀 Quick Start

### Option 1: Integrated VM Selection with Terraform (New!)

#### All Platforms (Go - Recommended)
```bash
# Build and run the integrated VM selector
go build -o select-vm1.exe select-vm1.go
.\select-vm1.exe

# Or use Make
make run-integrated

# Features:
# - Interactive VM type selection
# - Automatic terraform init/plan/apply
# - Uses per-module tfvars files
# - Cross-platform support
```

### Option 2: Interactive Selection (Legacy)

#### Windows (PowerShell)
```powershell
# Run the interactive selection script
.\select-vm-original.ps1

# Follow the prompts to select your VM type
# The script will automatically update terraform.tfvars
```

#### Linux/macOS (Bash)
```bash
# Set executable permissions and run
chmod +x select-vm.sh
./select-vm.sh

# Or use the installation script for Linux servers
chmod +x install-linux.sh
./install-linux.sh
```

### Option 3: Per-Module tfvars (Advanced)

### Option 2: Manual Configuration
```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars and set your desired vm_type
# Then run terraform commands
terraform init
terraform plan
terraform apply
```

## 📋 Available VM Types

| VM Type | Description | Authentication | Use Case |
|---------|-------------|----------------|----------|
| `basic_ssh` | Simple Linux VM | SSH Key | Development, Testing |
| `basic_password` | Simple Linux VM | Password | Quick setup, Learning |
| `custom_data` | VM with startup script | SSH Key | Pre-configured services |
| `public_ip` | VM with public IP | SSH Key | Internet-accessible services |
| `load_balanced` | Multiple VMs with LB | SSH Key | High availability, Scaling |

## ⚙️ Configuration

### Required Variables by VM Type

#### For SSH-based VMs (`basic_ssh`, `custom_data`, `public_ip`, `load_balanced`):
```hcl
vm_type = "basic_ssh"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAA... your-email@example.com"
```

#### For Password-based VMs (`basic_password`):
```hcl
vm_type = "basic_password"
admin_password = "<REDACTED - provide at runtime or via excluded tfvars>"
```

### Optional Configuration
```hcl
# Basic Infrastructure
resource_group_name = "rg-my-project"
location = "East US"
environment = "dev"
project_name = "my-project"

# VM Settings
admin_username = "azureadmin"
vm_size = "Standard_B2s"

# Load Balancer (only for load_balanced type)
load_balanced_vm_count = 3
```

## 🔧 Key Features

### User Input Validation
- **Automatic validation** ensures required variables are provided for selected VM type
- **Clear error messages** guide you to fix configuration issues
- **Input validation** prevents invalid VM type selections

### Single VM Deployment
- Only **ONE VM type** is deployed based on your selection
- No need to manage multiple boolean flags
- Simplified configuration and resource management

### Consistent Naming
- Automatic naming conventions: `{project_name}-{environment}-{vm_type}`
- Standardized resource tagging including VM type
- Organized resource grouping

## 📁 Project Structure

```
├── main.tf                     # Main Terraform configuration
├── variables.tf                # Variable definitions
├── locals.tf                   # Local values and computed configurations
├── outputs.tf                  # Output definitions
├── terraform.tfvars.example    # Example configuration
├── select-vm.ps1              # Interactive selection script (Windows)
├── select-vm.sh               # Interactive selection script (Linux/Bash)
├── select-vm.go               # Interactive selection script (Go)
├── install-linux.sh           # Linux installation script
├── Makefile                   # Build automation
├── README.md                  # This file
└── modules/                    # VM modules
    ├── basic-ssh/
    ├── basic-password/
    ├── custom-data/
    ├── public-ip/
    └── load-balanced/
```

## 🎯 Usage Examples

### Deploy a Public IP VM
```hcl
# terraform.tfvars
vm_type = "public_ip"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
project_name = "web-server"
environment = "prod"
```

### Deploy Load Balanced VMs
```hcl
# terraform.tfvars
vm_type = "load_balanced"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
load_balanced_vm_count = 3
project_name = "web-app"
```

### Deploy Custom Data VM
```hcl
# terraform.tfvars
vm_type = "custom_data"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E..."
custom_data = <<-EOF
#!/bin/bash
apt-get update
apt-get install -y apache2
systemctl start apache2
EOF
```

## 📤 Outputs

After deployment, you'll get connection information:

```bash
# SSH Connection
ssh azureadmin@20.10.30.40

# Web URL (for public_ip and load_balanced types)
http://20.10.30.40
```

## 🔍 Validation Rules

- **VM Type**: Must be one of the 5 supported types
- **SSH Key**: Required for all SSH-based VM types
- **Password**: Required for password-based VM types
- **VM Count**: Must be between 1-10 for load balanced VMs

## 🛠️ Commands

### Windows (PowerShell)
```powershell
# Interactive selection
.\select-vm.ps1

# Standard Terraform workflow
terraform init
terraform plan
terraform apply
terraform destroy

# Check outputs
terraform output
terraform output connection_info
```

### Linux/macOS (Bash)
```bash
# Interactive selection
./select-vm.sh

# Or with system-wide installation
vm-select

# Go version with Make
make run-go
make run-bash

# Standard Terraform workflow
terraform init
terraform plan  
terraform apply
terraform destroy

# Check outputs
terraform output
terraform output connection_info
```

### Linux Server Setup
```bash
# Quick installation
chmod +x install-linux.sh
./install-linux.sh

# Manual setup
chmod +x select-vm.sh
./select-vm.sh
```

## 🔒 Security Considerations

- SSH keys are recommended over passwords
- Consider restricting SSH access in production
- Use Azure Key Vault for sensitive data
- Review firewall rules before deployment

## 📚 Next Steps

1. **Customize modules** in the `modules/` directory
2. **Add monitoring** and logging configurations  
3. **Implement backup** strategies
4. **Set up CI/CD** pipelines for automated deployments

---

For questions or issues, please check the Terraform documentation or Azure provider documentation.