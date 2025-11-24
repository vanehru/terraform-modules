# RPG AIApp Infrastructure Terratest

This directory contains automated tests for the RPG AIApp infrastructure using [Terratest](https://terratest.gruntwork.io/).

## Overview

The test suite validates the complete infrastructure deployment including:
- Resource Group and Virtual Network
- Function App with VNet Integration
- Key Vault with Private Endpoints
- SQL Database with Private Endpoints
- Azure OpenAI with Private Endpoints
- Static Web App
- Network Security configurations

## Test Files

### Main Infrastructure Tests

- **`rpg_aiapp_infra_test.go`**: Complete infrastructure integration test
  - Tests all components deployed together
  - Validates resource creation
  - Verifies network configurations
  - Checks security settings

### Module-Specific Tests

- **`function_app_module_test.go`**: Function App module tests
- **`key_vault_module_test.go`**: Key Vault module tests
- **`sql_database_module_test.go`**: SQL Database module tests
- **`openai_module_test.go`**: Azure OpenAI module tests

### Integration Tests

- **`integration_test.go`**: End-to-end integration tests
  - Function App to Key Vault connectivity
  - Secret management validation
  - Private endpoint connectivity
  - Network isolation verification
  - Static Web App accessibility

## Prerequisites

### Required Tools

1. **Go** (version 1.21 or later)
   ```powershell
   go version
   ```

2. **Terraform** (version 1.0 or later)
   ```powershell
   terraform version
   ```

3. **Azure CLI**
   ```powershell
   az version
   ```

### Azure Authentication

Authenticate with Azure before running tests:

```powershell
az login
az account set --subscription <subscription-id>
```

### Environment Setup

Install Go dependencies:

```powershell
cd rpg-aiapp-infra/test
go mod download
```

## Running Tests

### Run All Tests

```powershell
cd rpg-aiapp-infra/test
go test -v -timeout 90m
```

### Run Specific Test

```powershell
# Run only the main infrastructure test
go test -v -timeout 90m -run TestRPGAIAppInfrastructure

# Run only Function App module test
go test -v -timeout 30m -run TestFunctionAppModule

# Run only integration tests
go test -v -timeout 60m -run TestIntegrationEndToEnd
```

### Run Tests in Parallel

```powershell
go test -v -timeout 90m -parallel 4
```

### Run with Detailed Output

```powershell
go test -v -timeout 90m 2>&1 | Tee-Object -FilePath test-results.log
```

## Test Structure

Each test follows this pattern:

1. **Setup Phase**
   - Generate unique resource names
   - Configure Terraform options
   - Set up test variables

2. **Deploy Phase**
   - Run `terraform init`
   - Run `terraform apply`

3. **Validation Phase**
   - Verify resource creation
   - Check configurations
   - Validate security settings
   - Test connectivity

4. **Cleanup Phase**
   - Run `terraform destroy`
   - Remove all created resources

## What Gets Tested

### Resource Creation
- ✅ Resource Group exists in correct location
- ✅ Virtual Network with correct address space
- ✅ All 6 subnets are properly configured
- ✅ Function App is deployed with managed identity
- ✅ Key Vault is created with access policies
- ✅ SQL Server and Database are deployed
- ✅ Azure OpenAI account with GPT models
- ✅ Static Web App is accessible

### Security Configurations
- ✅ Storage Account has private endpoints
- ✅ Key Vault denies public access
- ✅ SQL Server has private endpoints only
- ✅ OpenAI has private endpoints
- ✅ Function App uses VNet integration
- ✅ Network ACLs are properly configured

### Integration Points
- ✅ Function App can access Key Vault
- ✅ Secrets are stored in Key Vault
- ✅ Private DNS zones are configured
- ✅ Service endpoints are enabled
- ✅ Managed identity has correct permissions

## Test Configuration

### Custom Variables

You can override default variables by modifying the test files:

```go
terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
    TerraformDir: "../",
    Vars: map[string]interface{}{
        "azurerm_resource_group_location": "Japan East",
        "vnet_address_space": []string{"172.16.0.0/16"},
        // Add more custom variables
    },
})
```

### Test Timeouts

Default timeouts:
- Full infrastructure test: 90 minutes
- Module tests: 30 minutes
- Integration tests: 60 minutes

Adjust timeouts with `-timeout` flag:
```powershell
go test -v -timeout 120m
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Terratest

on:
  pull_request:
    paths:
      - 'rpg-aiapp-infra/**'
  
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: '1.6.0'
      
      - uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Run Terratest
        run: |
          cd rpg-aiapp-infra/test
          go test -v -timeout 90m
```

## Troubleshooting

### Common Issues

**Issue: Test timeout**
```
Solution: Increase timeout with -timeout flag
go test -v -timeout 120m
```

**Issue: Azure authentication failed**
```
Solution: Re-authenticate with Azure CLI
az login
az account set --subscription <subscription-id>
```

**Issue: Resource already exists**
```
Solution: Tests use unique IDs, but if resources remain from failed tests:
terraform destroy
# Or manually clean up in Azure Portal
```

**Issue: Quota limits**
```
Solution: Request quota increase or use different Azure region
az vm list-usage --location "Japan East" --output table
```

## Cost Considerations

Running tests deploys real Azure resources which incur costs:
- Function App: ~$0.10/hour
- SQL Database: ~$5/month (prorated)
- Azure OpenAI: ~$0.002/1K tokens
- Key Vault: ~$0.03/10K operations
- Static Web App: Free tier available

**Estimated test cost**: $2-5 per full test run

Always ensure `terraform destroy` completes successfully to avoid ongoing costs.

## Best Practices

1. **Run tests in a dedicated subscription** to isolate test resources
2. **Use unique resource names** to avoid conflicts (handled automatically)
3. **Clean up after tests** using defer terraform.Destroy
4. **Test in stages** - run module tests before full integration
5. **Monitor costs** using Azure Cost Management
6. **Run tests in parallel** when possible to save time
7. **Use test fixtures** for common configurations

## Contributing

When adding new tests:

1. Follow existing naming conventions
2. Add proper test documentation
3. Include cleanup logic (defer terraform.Destroy)
4. Use meaningful assertions
5. Test both success and failure scenarios
6. Update this README with new test information

## Resources

- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Azure Go SDK](https://github.com/Azure/azure-sdk-for-go)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Go Testing Package](https://pkg.go.dev/testing)

## Support

For issues or questions:
1. Check test logs for detailed error messages
2. Review Azure Portal for resource status
3. Verify Terraform configuration is valid
4. Check Azure service health status
5. Open an issue in the repository
