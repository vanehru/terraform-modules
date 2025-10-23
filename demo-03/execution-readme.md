# 🚀 Execution Guide: Simple Terraform VM Deployment


### **What You'll Learn**
- How to select a VM type and automatically run Terraform
- How each VM type uses its own configuration file (tfvars)
- How the system prevents configuration mistakes

---

## 🎯 **Method 1: Fully Automated (Recommended)**

### **Single Command Execution**
```bash
# Build and run the VM selector
go build -o select-vm1.exe select-vm1.go
.\select-vm1.exe
```

### **What You'll See**
```
=== Azure VM Deployment Tool ===
Select VM type and automatically run Terraform

1. Basic SSH VM
   Linux VM with SSH key authentication
   Requirements: SSH public key required
   Tfvars file: basic_ssh.tfvars

2. Basic Password VM
   Linux VM with password authentication  
   Requirements: Admin password required
   Tfvars file: basic_password.tfvars

3. Custom Data VM
   Linux VM with cloud-init custom data script
   Requirements: SSH public key required, Custom startup script included
   Tfvars file: custom_data.tfvars

4. Public IP VM
   Linux VM with public IP address
   Requirements: SSH public key required, Creates public IP
   Tfvars file: public_ip.tfvars

5. Load Balanced VM
   Multiple VMs behind Azure Load Balancer
   Requirements: SSH public key required, Creates 2+ VMs, Load balancer with public IP
   Tfvars file: load_balanced.tfvars

Enter your choice (1-5): 
```

### **Example Workflow**
```bash
# Step 1: Choose VM type
Enter your choice (1-5): 2

✓ Selected: Basic Password VM
Using tfvars file: basic_password.tfvars

# Step 2: Choose action
What would you like to do?
1. Plan (terraform plan)
2. Apply (terraform apply)
3. Apply with auto-approve (terraform apply -auto-approve)
Enter your choice (1-3): 1

# Step 3: Automatic execution
🚀 Running terraform plan with basic_password.tfvars...

Running terraform init...
Running terraform plan...
✓ Terraform plan completed successfully!
```

---

## 🎯 **Method 2: Manual Command (For Understanding)**

### **Step-by-Step Manual Process**
```bash
# 1. Choose your VM type configuration
cat tfvars/basic_password.tfvars

# 2. Initialize Terraform
terraform init

# 3. Plan with specific tfvars file
terraform plan -var-file "tfvars/basic_password.tfvars"

# 4. Apply if plan looks good
terraform apply -var-file "tfvars/basic_password.tfvars"
```

### **Alternative: Using PowerShell Wrapper**
```powershell
# Plan with basic password VM
.\scripts\terraform-with-tfvars.ps1 basic_password.tfvars plan

# Apply with basic password VM
.\scripts\terraform-with-tfvars.ps1 basic_password.tfvars apply
```

### **Alternative: Using Makefile**
```bash
# Plan with basic password VM
make plan-basic_password

# Apply with basic password VM  
make apply-basic_password
```

---

## 📁 **Understanding the File Structure**

### **Configuration Files (tfvars)**
```
tfvars/
├── basic_ssh.tfvars      # SSH key authentication VM
├── basic_password.tfvars # Password authentication VM
├── custom_data.tfvars   # VM with startup script  
├── public_ip.tfvars     # VM with public IP
└── load_balanced.tfvars # Multiple VMs with load balancer
```

### **Example: basic_password.tfvars**
```hcl
# Example tfvars for basic Password VM
admin_username = "azureadmin"
admin_password = "<REDACTED - provide at runtime or via excluded tfvars>"
vm_size = "Standard_D2s_v3"
vm_type = "basic_password"
enable_basic_ssh_vm = false
enable_basic_password_vm = true    # Only this VM type enabled
enable_custom_data_vm = false
enable_public_ip_vm = false
enable_load_balanced_vm = false
```

---

## 🔄 **How It Works Behind the Scenes**

### **1. Variable Processing**
```hcl
# In main.tf - your selected line (line 68)
module "basic_password_vm" {
  source = "./modules/basic-password"
  count  = local.create_basic_password_vm ? 1 : 0  # This becomes 1!

  prefix         = local.vm_names.basic_password
  location       = azurerm_resource_group.main.location
  admin_username = local.admin_username
  admin_password = var.admin_password
}
```

### **2. Conditional Logic**
```hcl
# When vm_type = "basic_password"
locals {
  create_basic_password_vm = var.vm_type == "basic_password"  # TRUE
  create_basic_ssh_vm      = var.vm_type == "basic_ssh"      # FALSE
  create_custom_data_vm    = var.vm_type == "custom_data"    # FALSE
  create_public_ip_vm      = var.vm_type == "public_ip"      # FALSE
  create_load_balanced_vm  = var.vm_type == "load_balanced"  # FALSE
}
```

### **3. Result**
- ✅ Only `basic_password_vm` module runs (count = 1)
- ❌ All other modules are skipped (count = 0)
- 🎯 Single VM type deployment, no conflicts

---

## 🛠️ **Before You Start**

### **Prerequisites**
```bash
# Check Terraform installation
terraform version

# Check Go installation (for automated tool)
go version

# Check Azure CLI (for authentication)
az --version
az login
```

### **Required Edits**
Before running, edit the tfvars files to replace placeholders:

```bash
# Generate SSH key pair (for SSH-based VMs)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key -N ""
# Then copy the public key content from ~/.ssh/azure_vm_key.pub

# Edit SSH public key in tfvars files
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your_actual_public_key_here"

# Edit admin password (for password-based VMs) 
admin_password = "<REDACTED - provide at runtime or via excluded tfvars>"
```

### **Quick SSH Key Setup**
```powershell
# Windows PowerShell - Generate SSH key
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\azure_vm_key -N '""'
Get-Content $env:USERPROFILE\.ssh\azure_vm_key.pub

# Copy the output and paste into ssh_public_key in your tfvars files
```

---

## 🎯 **Common Use Cases**

### **Testing Different VM Types**
```bash
# Test basic SSH VM
terraform plan -var-file "tfvars/basic_ssh.tfvars"

# Test basic password VM  
terraform plan -var-file "tfvars/basic_password.tfvars"

# Test custom data VM
terraform plan -var-file "tfvars/custom_data.tfvars"

# Alternative format (if paths contain spaces)
terraform plan -var-file tfvars/basic_ssh.tfvars
```

### **Deploying Specific VM Types**
```bash
# Deploy SSH VM for development
terraform apply -var-file "tfvars/basic_ssh.tfvars"

# Deploy password VM for Windows admins
terraform apply -var-file "tfvars/basic_password.tfvars"

# Deploy load balanced VMs for production
terraform apply -var-file "tfvars/load_balanced.tfvars"
```

### **Using the Automated Tool**
```bash
# Interactive deployment
.\select-vm1.exe

# Choose your VM type → Choose action → Done!
```

---

## 🚦 **Execution Flow Summary**

```
1. 📋 Select VM Type
   ↓
2. 📄 Load Corresponding tfvars File  
   ↓
3. ⚙️  Run terraform init
   ↓
4. 📊 Run terraform plan/apply with tfvars
   ↓
5. ✅ VM Deployed Successfully
```

---

## 🎓 **Key Learning Points for Juniors**

1. **One VM Type = One tfvars File**: Each VM type has its own configuration
2. **Automatic Selection**: The tool prevents configuration mistakes
3. **Modular Design**: Only the selected VM module runs
4. **Safe Testing**: Always run `plan` before `apply`
5. **Repeatable Process**: Same workflow for all VM types

---

## 🆘 **Troubleshooting**

### **Common Issues**
```bash
# Issue: "Too many command line arguments" error
# Cause: File paths with spaces (Japanese characters in OneDrive path)
# Solution: Use the Go tool (select-vm1.exe) or quote paths properly

# Issue: "parsing admin_ssh_key.0.public_key as a public key object" error
# Cause: Invalid SSH public key format in tfvars file
# Solution: Generate real SSH key pair and use the public key content
#   ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key -N ""
#   cat ~/.ssh/azure_vm_key.pub  # Copy this content to tfvars

# Issue: "Configuration errors: SSH public key is required for vm_type 'custom_data'"
# Cause: SSH key is null or placeholder value
# Solution: Set a valid SSH public key in the tfvars file

# Issue: PowerShell execution policy
# Solution: Use the Go tool instead of PowerShell scripts

# Issue: Missing SSH key
# Solution: Generate and add your SSH public key to tfvars file

# Issue: Terraform not found
# Solution: Install Terraform and add to PATH

# Issue: Azure authentication
# Solution: Run 'az login' to authenticate
```

### **Validation Errors**
The system automatically validates your configuration:
- ❌ SSH key missing for SSH-based VMs
- ❌ Password missing for password-based VMs  
- ✅ All requirements met

---

## 🎯 **Next Steps**

1. **Run the automated tool**: `.\select-vm1.exe`
2. **Choose a VM type**: Start with Basic Password VM (option 2)
3. **Run plan first**: Choose option 1 to see what will be created
4. **Apply when ready**: Choose option 2 to deploy resources
5. **Clean up**: Run `terraform destroy -var-file=tfvars/[your-choice].tfvars`

**🎉 You're ready to deploy Azure VMs like a pro!**