# Terratest for RPG AIApp Infrastructure - Command Reference

Quick reference for all test commands and common operations.

## Prerequisites Check

```powershell
# Check Go installation
go version
# Expected: go version go1.21.x or higher

# Check Terraform installation
terraform version
# Expected: Terraform v1.0.x or higher

# Check Azure CLI
az version
# Expected: azure-cli version 2.x.x or higher

# Check Azure authentication
az account show
# Should show your current subscription
```

## Initial Setup

```powershell
# Navigate to test directory
cd C:\Users\nehru\OneDrive\Devops\terraform-modules-1\rpg-aiapp-infra\test

# Download Go dependencies (first time only)
go mod download

# Tidy up dependencies
go mod tidy

# Verify module
go mod verify
```

## Azure Authentication

```powershell
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "<subscription-id>"

# Verify current subscription
az account show

# Get current tenant and subscription info
az account show --query "{subscriptionId:id, tenantId:tenantId}"
```

## Running Tests

### Individual Module Tests

```powershell
# Function App module (15-30 min, ~$1-2)
go test -v -timeout 30m -run TestFunctionAppModule

# Key Vault module (15-30 min, ~$1-2)
go test -v -timeout 30m -run TestKeyVaultModule

# SQL Database module (15-30 min, ~$1-2)
go test -v -timeout 30m -run TestSQLDatabaseModule

# Azure OpenAI module (15-30 min, ~$1-2)
go test -v -timeout 30m -run TestOpenAIModule
```

### Combined Module Tests

```powershell
# Run all module tests (60-90 min, ~$4-8)
go test -v -timeout 90m -run "Module"

# Run all module tests in parallel (45-60 min, ~$4-8)
go test -v -timeout 90m -parallel 4 -run "Module"
```

### Integration Tests

```powershell
# Run integration tests (45-60 min, ~$2-3)
go test -v -timeout 60m -run TestIntegrationEndToEnd

# Run with detailed logging
go test -v -timeout 60m -run TestIntegrationEndToEnd 2>&1 | Tee-Object integration.log
```

### Full Infrastructure Test

```powershell
# Run complete infrastructure test (90-120 min, ~$3-5)
go test -v -timeout 120m -run TestRPGAIAppInfrastructure

# Run with logging
go test -v -timeout 120m -run TestRPGAIAppInfrastructure 2>&1 | Tee-Object full-test.log
```

### Run All Tests

```powershell
# Run all tests sequentially (2-4 hours, ~$10-15)
go test -v -timeout 240m

# Run all tests in parallel (1-2 hours, ~$10-15)
go test -v -timeout 180m -parallel 4
```

## Test Output Options

```powershell
# Verbose output
go test -v -run TestName

# With timeout
go test -v -timeout 30m -run TestName

# Short test mode (skips long-running tests)
go test -v -short

# With test coverage
go test -v -cover -run TestName

# Generate coverage report
go test -v -coverprofile=coverage.out -run TestName
go tool cover -html=coverage.out -o coverage.html

# JSON output
go test -v -json -run TestName

# Save output to file
go test -v -run TestName 2>&1 | Tee-Object test-output.log
```

## Using PowerShell Helper Script

```powershell
# Load helper functions
. .\test-helpers.ps1

# Initialize
init

# Run tests
test-function-app    # Function App module test
test-key-vault       # Key Vault module test
test-sql             # SQL Database module test
test-openai          # OpenAI module test
test-module          # All module tests
test-integration     # Integration tests
test                 # Main infrastructure test
test-all             # All tests

# Utilities
clean                # Clean test cache
fmt                  # Format Go code
test-with-log        # Run tests with logging
test-parallel        # Run tests in parallel
```

## Using Makefile (if on WSL/Linux/Mac)

```bash
make help              # Show all available targets
make init              # Initialize dependencies
make test              # Run main test
make test-module       # Run all module tests
make test-integration  # Run integration tests
make test-all          # Run all tests
make test-function-app # Run Function App test
make test-key-vault    # Run Key Vault test
make test-sql          # Run SQL test
make test-openai       # Run OpenAI test
make clean             # Clean test cache
make fmt               # Format code
make coverage          # Run with coverage
make test-parallel     # Run in parallel
```

## Monitoring Tests

### Watch Azure Resources (in another terminal)

```powershell
# List test resource groups
az group list --query "[?starts_with(name, 'rpg-aiapp-rg-test-')]" --output table

# Watch specific resource group
$rgName = "rpg-aiapp-rg-test-xxxxx"
az resource list --resource-group $rgName --output table

# Continuous monitoring (refresh every 30 seconds)
while ($true) {
    Clear-Host
    Write-Host "Resources at $(Get-Date)" -ForegroundColor Green
    az resource list --resource-group $rgName --output table
    Start-Sleep -Seconds 30
}
```

### Monitor Test Progress

```powershell
# Tail test output file
Get-Content -Path test-output.log -Wait -Tail 20

# Watch for specific patterns
Get-Content -Path test-output.log -Wait | Where-Object { $_ -match "PASS|FAIL|Error" }
```

## Cleanup Operations

```powershell
# Clean test cache
go clean -testcache

# Remove test logs
Remove-Item -Path *.log -Force

# Remove coverage files
Remove-Item -Path coverage.* -Force

# List orphaned test resource groups
az group list --query "[?starts_with(name, 'rpg-aiapp-rg-test-')]" --output table

# Delete all test resource groups (CAREFUL!)
az group list --query "[?starts_with(name, 'rpg-aiapp-rg-test-')].name" -o tsv | `
    ForEach-Object { az group delete --name $_ --yes --no-wait }

# Delete specific test resource group
az group delete --name rpg-aiapp-rg-test-xxxxx --yes --no-wait

# Wait for deletion to complete
az group wait --name rpg-aiapp-rg-test-xxxxx --deleted

# Check deletion status
az group exists --name rpg-aiapp-rg-test-xxxxx
```

## Troubleshooting Commands

```powershell
# Verify Go environment
go env

# List Go modules
go list -m all

# Check for module updates
go list -u -m all

# Update specific module
go get -u github.com/gruntwork-io/terratest

# Update all modules
go get -u ./...

# Download missing modules
go mod download

# Verify module checksums
go mod verify

# Clean module cache
go clean -modcache

# Re-initialize Terraform
cd ..\
terraform init -reconfigure

# Validate Terraform configuration
terraform validate

# Check Terraform formatting
terraform fmt -check -recursive

# Format Terraform files
terraform fmt -recursive
```

## Azure Cost Management

```powershell
# View current costs
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31

# List resources with costs
az resource list --query "[].{name:name, type:type, resourceGroup:resourceGroup}" --output table

# Check resource group costs (in Portal)
Start-Process "https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/costanalysis"

# Calculate estimated test costs
# Function App P1v2: ~$0.10/hour
# SQL Basic: ~$5/month (prorated)
# OpenAI: ~$0.002/1K tokens
# Storage: ~$0.02/GB
# Estimated total per full test: $3-5
```

## Environment Variables (Optional)

```powershell
# Set Azure credentials for service principal authentication
$env:ARM_CLIENT_ID = "your-client-id"
$env:ARM_CLIENT_SECRET = "your-client-secret"
$env:ARM_SUBSCRIPTION_ID = "your-subscription-id"
$env:ARM_TENANT_ID = "your-tenant-id"

# Set test configuration
$env:TEST_REGION = "Japan East"
$env:TEST_TIMEOUT = "120m"

# Disable Terraform color output
$env:TF_CLI_ARGS = "-no-color"

# Enable Terraform debugging (verbose)
$env:TF_LOG = "DEBUG"
$env:TF_LOG_PATH = "terraform-debug.log"
```

## CI/CD Integration

```powershell
# Test locally before pushing
go test -v -short -timeout 10m

# Run module tests (PR validation)
go test -v -timeout 60m -run "Module"

# Full test (pre-merge)
go test -v -timeout 120m -run TestRPGAIAppInfrastructure

# Format code before commit
go fmt ./...
terraform fmt -recursive
```

## Performance Optimization

```powershell
# Run specific subtests only
go test -v -run TestRPGAIAppInfrastructure/ResourceGroupExists

# Skip cleanup for debugging (CAREFUL - manual cleanup required)
# Modify test to comment out: defer terraform.Destroy(t, terraformOptions)

# Use shorter timeouts for faster failure
go test -v -timeout 15m -run TestFunctionAppModule

# Cache Go build
go build -i ./...

# Parallel execution (maximum performance)
go test -v -timeout 90m -parallel 8
```

## Development Workflow

```powershell
# 1. Make changes to Terraform code
cd ..\
# Edit main.tf, variables.tf, etc.

# 2. Format and validate
terraform fmt -recursive
terraform validate

# 3. Update tests if needed
cd test\
# Edit *_test.go files

# 4. Format test code
go fmt ./...

# 5. Run relevant module test
go test -v -timeout 30m -run TestFunctionAppModule

# 6. Run integration test
go test -v -timeout 60m -run TestIntegrationEndToEnd

# 7. Run full test before merging
go test -v -timeout 120m -run TestRPGAIAppInfrastructure

# 8. Clean up
clean
```

## Useful Test Flags

```powershell
# -v              : Verbose output
# -timeout        : Maximum test duration
# -run            : Run specific test by pattern
# -parallel       : Number of tests to run in parallel
# -short          : Skip long-running tests
# -cover          : Show coverage information
# -coverprofile   : Save coverage to file
# -json           : Output in JSON format
# -count          : Run tests N times
# -failfast       : Stop on first failure

# Examples:
go test -v -timeout 30m -run TestKeyVault -failfast
go test -v -short -cover
go test -v -count=3 -run TestFunctionAppModule  # Run 3 times
```

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│                    QUICK COMMANDS                       │
├─────────────────────────────────────────────────────────┤
│ Setup:           go mod download                        │
│ Auth:            az login                               │
│ Test Module:     go test -v -timeout 30m -run Module   │
│ Test Full:       go test -v -timeout 120m              │
│ Clean:           go clean -testcache                    │
│ Format:          go fmt ./...                           │
│ Cleanup Azure:   az group delete --name <rg> --yes     │
├─────────────────────────────────────────────────────────┤
│ Cost per run: $1-2 (module) | $3-5 (full)             │
│ Duration: 15-30m (module) | 90-120m (full)             │
└─────────────────────────────────────────────────────────┘
```

## Getting Help

```powershell
# Go test help
go help test
go help testflag

# Terraform help
terraform --help
az --help

# View test documentation
Get-Content README.md
Get-Content QUICKSTART.md
Get-Content SUMMARY.md

# View examples
Get-Content examples_test.go
```

---

**Pro Tip**: Start with module tests for quick feedback, then run integration tests, and finally full infrastructure tests before merging to production.

**Remember**: Always ensure `terraform destroy` completes to avoid ongoing Azure costs!
