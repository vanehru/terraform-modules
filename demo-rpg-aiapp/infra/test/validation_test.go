package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TestTerraformValidation validates the Terraform configuration syntax
func TestTerraformValidation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		NoColor:      true,
	})

	// Validate the Terraform configuration
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

// TestTerraformPlan tests that terraform plan runs without errors
func TestTerraformPlan(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"azurerm_resource_group_name":     "test-rg-plan",
			"azurerm_resource_group_location": "Japan East",
		},
		NoColor: true,
	})

	// Initialize and plan
	terraform.Init(t, terraformOptions)
	terraform.Plan(t, terraformOptions)
}

// TestModuleStructure validates that all required modules exist
func TestModuleStructure(t *testing.T) {
	t.Parallel()

	// Test that module directories exist
	modules := []string{
		"../modules/function-app",
		"../modules/key-vault",
		"../modules/openai",
		"../modules/sql-database",
		"../modules/static-web-app",
	}

	for _, module := range modules {
		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			TerraformDir: module,
			NoColor:      true,
		})

		// Validate each module
		terraform.Init(t, terraformOptions)
		terraform.Validate(t, terraformOptions)
	}
}