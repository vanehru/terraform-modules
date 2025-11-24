# RPG AIApp Infrastructure Tests - Quick Start Guide

This guide helps you quickly set up and run Terratest for the RPG AIApp infrastructure.

## Prerequisites Checklist

- [ ] Go 1.21+ installed
- [ ] Terraform 1.0+ installed
- [ ] Azure CLI installed
- [ ] Azure subscription with appropriate permissions
- [ ] Authenticated with Azure CLI

## Quick Setup (5 minutes)

### 1. Install Prerequisites

**Windows (PowerShell):**
```powershell
# Install Go
winget install GoLang.Go

# Install Terraform
winget install Hashicorp.Terraform

# Install Azure CLI
winget install Microsoft.AzureCLI

# Verify installations
go version
terraform version
az version
```

### 2. Authenticate with Azure

```powershell
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Verify current subscription
az account show
```

### 3. Initialize Test Environment

```powershell
# Navigate to test directory
cd rpg-aiapp-infra\test

# Download Go dependencies
go mod download

# Verify setup
go test -v -run TestNone  # Should pass with no tests
```

## Running Your First Test

### Option 1: Quick Module Test (10-15 minutes)

Test a single module first to verify everything works:

```powershell
cd rpg-aiapp-infra\test
go test -v -timeout 30m -run TestFunctionAppModule
```

### Option 2: Full Infrastructure Test (90+ minutes)

Deploy and test the complete infrastructure:

```powershell
cd rpg-aiapp-infra\test
go test -v -timeout 120m -run TestRPGAIAppInfrastructure
```

### Option 3: Using Helper Scripts (Recommended)

**Windows:**
```powershell
# Initialize
.\test-helpers.ps1 init

# Run module tests
.\test-helpers.ps1 test-module

# Run integration tests
.\test-helpers.ps1 test-integration

# Run all tests
.\test-helpers.ps1 test-all
```

## Test Execution Flow

```
┌─────────────────────────────────────────────┐
│  1. Setup (Generate unique names)           │
│     ↓                                        │
│  2. Terraform Init                           │
│     ↓                                        │
│  3. Terraform Apply (Deploy infrastructure) │
│     ↓                                        │
│  4. Validation Tests                         │
│     - Resource existence                     │
│     - Configuration verification             │
│     - Security checks                        │
│     - Integration validation                 │
│     ↓                                        │
│  5. Terraform Destroy (Cleanup)             │
└─────────────────────────────────────────────┘
```

## Understanding Test Output

### Success Example:
```
=== RUN   TestRPGAIAppInfrastructure
=== RUN   TestRPGAIAppInfrastructure/ResourceGroupExists
--- PASS: TestRPGAIAppInfrastructure/ResourceGroupExists (2.34s)
=== RUN   TestRPGAIAppInfrastructure/VNetConfiguration
--- PASS: TestRPGAIAppInfrastructure/VNetConfiguration (1.89s)
...
--- PASS: TestRPGAIAppInfrastructure (1234.56s)
PASS
ok      github.com/vanehru/terraform-modules/rpg-aiapp-infra/test   1234.567s
```

### Failure Example:
```
=== RUN   TestRPGAIAppInfrastructure
=== RUN   TestRPGAIAppInfrastructure/ResourceGroupExists
    rpg_aiapp_infra_test.go:85: 
        Error: Resource group rpg-aiapp-rg-test-abc123 does not exist
--- FAIL: TestRPGAIAppInfrastructure/ResourceGroupExists (5.23s)
```

## Common Test Commands

```powershell
# Run specific test by name
go test -v -run TestFunctionAppModule

# Run with detailed logging
go test -v -timeout 90m 2>&1 | Tee-Object test-results.log

# Run tests in parallel (faster)
go test -v -parallel 4 -timeout 120m

# Run only integration tests
go test -v -run "Integration" -timeout 60m

# Clean test cache
go clean -testcache

# Format test code
go fmt ./...
```

## Test Types Overview

| Test Type | Duration | Cost | Use Case |
|-----------|----------|------|----------|
| **Module Tests** | 15-30 min | $1-2 | Validate individual modules |
| **Integration Tests** | 45-60 min | $2-3 | Test component interactions |
| **Full Infrastructure** | 90-120 min | $3-5 | Complete deployment validation |

## Monitoring Test Progress

### In Another Terminal:
```powershell
# Watch Azure resources being created
az resource list --resource-group rpg-aiapp-rg-test-* --output table

# Monitor Function App logs
az functionapp log tail --name <function-app-name> --resource-group <rg-name>
```

## Troubleshooting Quick Fixes

### Issue: "Azure authentication failed"
```powershell
az logout
az login
az account set --subscription "<subscription-id>"
```

### Issue: "Test timeout"
```powershell
# Increase timeout
go test -v -timeout 180m -run TestRPGAIAppInfrastructure
```

### Issue: "Resource already exists"
```powershell
# Clean up manually
az group list --tag "terratest=true" --query "[].name" -o tsv | ForEach-Object {
    az group delete --name $_ --yes --no-wait
}
```

### Issue: "Terraform locked"
```powershell
# Remove local state
cd rpg-aiapp-infra
Remove-Item -Recurse -Force .terraform, .terraform.lock.hcl
```

## Cost Management

### Before Running Tests:
```powershell
# Check current costs
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31

# Set spending alert (optional)
# Configure in Azure Portal > Cost Management
```

### After Running Tests:
```powershell
# Verify all resources are deleted
az group list --query "[?starts_with(name, 'rpg-aiapp-rg-test-')]" -o table

# Force cleanup if needed
az group list --query "[?starts_with(name, 'rpg-aiapp-rg-test-')].name" -o tsv | `
    ForEach-Object { az group delete --name $_ --yes --no-wait }
```

## Best Practices

1. **Start Small**: Run module tests before full infrastructure tests
2. **Watch Costs**: Monitor Azure costs during testing
3. **Clean Up**: Always ensure `terraform destroy` completes
4. **Use Logs**: Save test output for debugging
5. **Parallel Testing**: Use `-parallel` flag for faster execution
6. **Test in Stages**: Validate modules → Integration → Full deployment

## Next Steps

After successful test run:

1. ✅ Review test output for any warnings
2. ✅ Verify all resources are deleted in Azure Portal
3. ✅ Check Azure costs
4. ✅ Read detailed README.md for advanced usage
5. ✅ Customize tests for your specific requirements

## Getting Help

- Check `README.md` for detailed documentation
- Review test logs: `test-results.log`
- Check Azure Portal for resource status
- Review Terraform output: `terraform show`

## Estimated Times

- **First-time setup**: 10-15 minutes
- **Module test**: 15-30 minutes
- **Integration test**: 45-60 minutes
- **Full infrastructure test**: 90-120 minutes

## Success Criteria

Your test is successful when you see:
- ✅ All sub-tests pass
- ✅ Resources are created correctly
- ✅ Terraform destroy completes
- ✅ No resources remain in Azure Portal
- ✅ Final output shows `PASS`

Happy Testing! 🚀
