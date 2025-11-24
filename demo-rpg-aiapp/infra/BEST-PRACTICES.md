# Infrastructure Best Practices

## Overview

This document outlines the best practices implemented in the RPG AI Application infrastructure and provides guidelines for maintaining and extending the codebase.

## Terraform Best Practices

### 1. Code Organization

#### Module Structure
```
infra/
├── main.tf              # Root module configuration
├── variables.tf         # Input variables with validation
├── outputs.tf           # Output values
├── providers.tf         # Provider configuration
├── terraform.tfvars.example  # Example configuration
└── modules/
    ├── function-app/    # Reusable Function App module
    ├── key-vault/       # Reusable Key Vault module
    └── sql-database/    # Reusable SQL Database module
```

#### File Naming Conventions
- `main.tf`: Primary resource definitions
- `variables.tf`: Input variable declarations
- `outputs.tf`: Output value definitions
- `providers.tf`: Provider and version constraints

### 2. Variable Management

#### Input Validation
```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

#### Consistent Naming
```hcl
locals {
  name_prefix = "${var.environment}-rpg"
  common_tags = {
    project_owner = var.project_owner
    author        = var.author
    environment   = var.environment
    project       = "rpg-aiapp"
    managed_by    = "terraform"
  }
}
```

### 3. Resource Management

#### Lifecycle Rules
```hcl
resource "random_password" "sql_admin_password" {
  length = 32
  
  lifecycle {
    ignore_changes = [length, special, min_lower, min_upper]
  }
}
```

#### Dependency Management
```hcl
depends_on = [
  module.sql_database,
  module.openai
]
```

### 4. Security Hardening

#### Provider Security Features
```hcl
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
```

#### Resource Security Defaults
```hcl
# Always enforce HTTPS
https_only = true

# Minimum TLS version
minimum_tls_version = "1.2"

# Disable public access by default
public_network_access_enabled = false
```

## Azure Architecture Best Practices

### 1. Network Design

#### Subnet Segmentation
- **Application Subnet**: Function App and web services
- **Storage Subnet**: Storage account private endpoints
- **Database Subnet**: SQL Database private endpoints
- **Key Vault Subnet**: Key Vault private endpoints
- **OpenAI Subnet**: Azure OpenAI private endpoints
- **Deployment Subnet**: Management and deployment tools

#### Private Endpoints
```hcl
# Standard private endpoint pattern
resource "azurerm_private_endpoint" "example" {
  name                = "${var.service_name}-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.service_name}-connection"
    private_connection_resource_id = azurerm_service.example.id
    subresource_names              = ["targetSubResource"]
    is_manual_connection           = false
  }
}
```

### 2. Security Implementation

#### Network Security Groups
```hcl
resource "azurerm_network_security_group" "app_nsg" {
  name = "${local.name_prefix}-app-nsg"
  
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_port_range     = "443"
  }
  
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
  }
}
```

#### Managed Identity Usage
```hcl
# User-assigned managed identity
resource "azurerm_user_assigned_identity" "func_identity" {
  name                = "${var.function_app_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# Function App with managed identity
identity {
  type         = "UserAssigned"
  identity_ids = [azurerm_user_assigned_identity.func_identity.id]
}
```

### 3. Cost Optimization

#### Resource Sizing
- **Function App**: P1v2 for production workloads
- **SQL Database**: GP_S_Gen5_2 for serverless scaling
- **Storage**: LRS replication for cost efficiency
- **Key Vault**: Standard tier for most use cases

#### Monitoring and Alerting
```hcl
# Cost monitoring tags
tags = merge(local.common_tags, {
  cost_center = var.cost_center
  budget_code = var.budget_code
})
```

## Development Workflow

### 1. Code Quality

#### Pre-commit Hooks
```bash
# Install pre-commit hooks
pre-commit install

# Hooks include:
# - terraform fmt
# - terraform validate
# - tflint
# - checkov (security scanning)
```

#### Code Formatting
```bash
# Format all Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan with detailed output
terraform plan -detailed-exitcode
```

### 2. Testing Strategy

#### Unit Tests
```go
func TestFunctionAppModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/function-app",
        Vars: map[string]interface{}{
            "function_app_name": "test-func-app",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    // Validate outputs
    functionAppId := terraform.Output(t, terraformOptions, "function_app_id")
    assert.NotEmpty(t, functionAppId)
}
```

#### Integration Tests
```go
func TestCompleteInfrastructure(t *testing.T) {
    // Test full infrastructure deployment
    // Validate connectivity between components
    // Verify security configurations
}
```

### 3. CI/CD Integration

#### GitHub Actions Workflow
```yaml
name: Terraform CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform fmt -check
      - run: terraform validate
      - run: terraform plan
```

## Monitoring and Observability

### 1. Logging Strategy

#### Centralized Logging
- **Azure Monitor**: Centralized log collection
- **Application Insights**: Application performance monitoring
- **Key Vault Logs**: Secret access auditing

#### Log Retention
```hcl
# Configure log retention
log_analytics_workspace {
  retention_in_days = 30
  daily_quota_gb    = 1
}
```

### 2. Alerting

#### Critical Alerts
- Function App failures
- Key Vault access denials
- SQL Database connection failures
- Storage account access issues

#### Performance Alerts
- High CPU utilization
- Memory pressure
- Network latency issues

## Disaster Recovery

### 1. Backup Strategy

#### Automated Backups
- **SQL Database**: Point-in-time restore enabled
- **Key Vault**: Soft delete and purge protection
- **Storage Account**: Versioning and soft delete

#### Recovery Procedures
```bash
# Infrastructure recovery
terraform plan -destroy
terraform apply -auto-approve

# Data recovery
az sql db restore --dest-name recovered-db \
  --source-db original-db \
  --time "2023-01-01T00:00:00Z"
```

### 2. High Availability

#### Multi-Region Considerations
- **Traffic Manager**: DNS-based load balancing
- **Geo-Replication**: SQL Database cross-region replication
- **Storage Replication**: GRS for critical data

## Performance Optimization

### 1. Function App Performance

#### Cold Start Mitigation
```hcl
app_settings = {
  "WEBSITE_RUN_FROM_PACKAGE"     = "1"
  "FUNCTIONS_WORKER_RUNTIME"     = "python"
  "WEBSITE_CONTENTOVERVNET"      = "1"
}
```

#### Scaling Configuration
```hcl
site_config {
  pre_warmed_instance_count = 1
  elastic_instance_minimum  = 1
}
```

### 2. Database Performance

#### Connection Pooling
```hcl
# SQL Database configuration
sku_name    = "GP_S_Gen5_2"  # Serverless for variable workloads
max_size_gb = 32             # Appropriate sizing
```

## Maintenance Procedures

### 1. Regular Updates

#### Terraform Provider Updates
```bash
# Update provider versions
terraform init -upgrade

# Review changes
terraform plan

# Apply updates
terraform apply
```

#### Security Patches
- Monthly security review
- Automated vulnerability scanning
- Dependency updates

### 2. Configuration Drift

#### Drift Detection
```bash
# Detect configuration drift
terraform plan -detailed-exitcode

# Import existing resources
terraform import azurerm_resource_group.example /subscriptions/.../resourceGroups/example
```

## Documentation Standards

### 1. Code Documentation

#### Inline Comments
```hcl
# Network Security Group for Application Subnet
# Restricts inbound traffic to HTTPS only
resource "azurerm_network_security_group" "app_nsg" {
  # Configuration...
}
```

#### README Structure
- Overview and architecture
- Prerequisites and setup
- Configuration options
- Deployment instructions
- Troubleshooting guide

### 2. Change Documentation

#### Change Log Format
```markdown
## [1.2.0] - 2023-12-01
### Added
- Private endpoint for Azure OpenAI
- Network security group for application subnet

### Changed
- Updated Function App runtime to Python 3.11
- Increased SQL Database retention period

### Security
- Enforced TLS 1.2 minimum across all services
- Added managed identity for container instances
```

## Troubleshooting Guide

### Common Issues

#### Authentication Failures
```bash
# Check managed identity assignment
az role assignment list --assignee <identity-id>

# Verify Key Vault access policies
az keyvault show --name <vault-name> --query properties.accessPolicies
```

#### Network Connectivity
```bash
# Test private endpoint resolution
nslookup <service>.privatelink.database.windows.net

# Check NSG rules
az network nsg rule list --resource-group <rg> --nsg-name <nsg>
```

#### Resource Deployment Failures
```bash
# Check deployment status
az deployment group show --resource-group <rg> --name <deployment>

# Review activity logs
az monitor activity-log list --resource-group <rg>
```

## Support and Contacts

### Team Contacts
- **Infrastructure Team**: infrastructure@company.com
- **Security Team**: security@company.com
- **DevOps Team**: devops@company.com

### External Resources
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)