package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestFunctionAppModule tests the Function App module independently
func TestFunctionAppModule(t *testing.T) {
	t.Parallel()

	uniqueID := strings.ToLower(random.UniqueId())
	resourceGroupName := fmt.Sprintf("test-func-rg-%s", uniqueID)
	functionAppName := fmt.Sprintf("testfunc%s", uniqueID)
	storageAccountName := fmt.Sprintf("teststg%s", uniqueID)
	location := "Japan East"

	// Create test resource group and VNet first
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/function-app",
		Vars: map[string]interface{}{
			"function_app_name":                functionAppName,
			"location":                         location,
			"resource_group_name":              resourceGroupName,
			"storage_account_name":             storageAccountName,
			"storage_account_tier":             "Standard",
			"storage_account_replication_type": "LRS",
			"app_service_plan_name":            fmt.Sprintf("test-plan-%s", uniqueID),
			"app_service_plan_sku":             "P1v2",
			"create_managed_identity":          true,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test Function App exists
	t.Run("FunctionAppExists", func(t *testing.T) {
		actualFunctionAppName := terraform.Output(t, terraformOptions, "function_app_name")
		assert.Equal(t, functionAppName, actualFunctionAppName)

		exists := azure.AppExists(t, actualFunctionAppName, resourceGroupName, "")
		assert.True(t, exists, "Function App should exist")
	})

	// Test Storage Account exists
	t.Run("StorageAccountExists", func(t *testing.T) {
		storageAcctName := terraform.Output(t, terraformOptions, "storage_account_name")
		assert.Equal(t, storageAccountName, storageAcctName)

		exists := azure.StorageAccountExists(t, storageAcctName, resourceGroupName, "")
		assert.True(t, exists, "Storage Account should exist")
	})

	// Test Managed Identity
	t.Run("ManagedIdentityEnabled", func(t *testing.T) {
		principalID := terraform.Output(t, terraformOptions, "function_app_identity_principal_id")
		assert.NotEmpty(t, principalID, "Function App should have managed identity")
	})

	// Test App Service Plan
	t.Run("AppServicePlanExists", func(t *testing.T) {
		planName := terraform.Output(t, terraformOptions, "app_service_plan_name")
		assert.NotEmpty(t, planName, "App Service Plan should be created")
	})
}
