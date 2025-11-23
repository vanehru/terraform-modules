package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Example_BasicTest demonstrates a basic Terratest structure
func Example_BasicTest() {
	// This is a documentation example - not an actual test
	// It shows the basic pattern for writing Terratest tests
}

// TestExample_MinimalInfrastructure shows a minimal test example
func TestExample_MinimalInfrastructure(t *testing.T) {
	// Skip this test by default - it's just an example
	t.Skip("This is an example test - skip by default")

	// Configure Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"azurerm_resource_group_name": "example-rg",
		},
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	rgName := terraform.Output(t, terraformOptions, "resource_group_name")
	assert.Equal(t, "example-rg", rgName)
}

// TestExample_WithRetry demonstrates how to use retry logic for eventual consistency
func TestExample_WithRetry(t *testing.T) {
	t.Skip("This is an example test - skip by default")

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Some Azure resources need time to become fully available
	maxRetries := 10
	timeBetweenRetries := 30 * time.Second

	_, err := retry.DoWithRetryE(
		t,
		"Wait for resource to be ready",
		maxRetries,
		timeBetweenRetries,
		func() (string, error) {
			// Your validation logic here
			output := terraform.Output(t, terraformOptions, "endpoint")
			if output == "" {
				return "", fmt.Errorf("endpoint not ready yet")
			}
			return output, nil
		},
	)

	require.NoError(t, err, "Resource should become ready within timeout")
}

// TestExample_TableDrivenTests demonstrates table-driven test pattern
func TestExample_TableDrivenTests(t *testing.T) {
	t.Skip("This is an example test - skip by default")

	testCases := []struct {
		name     string
		location string
		expected string
	}{
		{
			name:     "JapanEast",
			location: "Japan East",
			expected: "japaneast",
		},
		{
			name:     "EastUS",
			location: "East US",
			expected: "eastus",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := &terraform.Options{
				TerraformDir: "../",
				Vars: map[string]interface{}{
					"azurerm_resource_group_location": tc.location,
				},
			}

			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			location := terraform.Output(t, terraformOptions, "resource_group_location")
			assert.Contains(t, location, tc.expected)
		})
	}
}

// TestExample_SubTests demonstrates organizing tests with subtests
func TestExample_SubTests(t *testing.T) {
	t.Skip("This is an example test - skip by default")

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Run multiple validation tests as subtests
	t.Run("ValidateResourceGroup", func(t *testing.T) {
		rgName := terraform.Output(t, terraformOptions, "resource_group_name")
		assert.NotEmpty(t, rgName)
	})

	t.Run("ValidateVNet", func(t *testing.T) {
		vnetName := terraform.Output(t, terraformOptions, "vnet_name")
		assert.NotEmpty(t, vnetName)
	})

	t.Run("ValidateTags", func(t *testing.T) {
		// Validate that resources have required tags
		tags := terraform.OutputMap(t, terraformOptions, "resource_tags")
		assert.Contains(t, tags, "environment")
		assert.Contains(t, tags, "project_owner")
	})
}

// TestExample_ErrorHandling demonstrates proper error handling
func TestExample_ErrorHandling(t *testing.T) {
	t.Skip("This is an example test - skip by default")

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"invalid_variable": "this_should_fail",
		},
	}

	// Expect this to fail
	_, err := terraform.InitAndApplyE(t, terraformOptions)

	// Use require.Error when you expect an error
	require.Error(t, err, "Should fail with invalid variable")

	// Optionally verify the error message
	assert.Contains(t, err.Error(), "invalid")
}

// TestExample_ConditionalTests demonstrates conditional test execution
func TestExample_ConditionalTests(t *testing.T) {
	t.Skip("This is an example test - skip by default")

	// Only run expensive tests on certain conditions
	if testing.Short() {
		t.Skip("Skipping expensive test in short mode")
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Run expensive validations
	t.Log("Running expensive test operations...")
}

// TestExample_ParallelExecution demonstrates parallel test execution
func TestExample_ParallelExecution(t *testing.T) {
	t.Skip("This is an example test - skip by default")

	testCases := []struct {
		name string
		size string
	}{
		{"Small", "Basic"},
		{"Medium", "S1"},
		{"Large", "P1v2"},
	}

	for _, tc := range testCases {
		tc := tc // Capture range variable
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel() // Run this test in parallel with others

			terraformOptions := &terraform.Options{
				TerraformDir: "../",
				Vars: map[string]interface{}{
					"sku_size": tc.size,
				},
			}

			defer terraform.Destroy(t, terraformOptions)
			terraform.InitAndApply(t, terraformOptions)

			sku := terraform.Output(t, terraformOptions, "sku_name")
			assert.Equal(t, tc.size, sku)
		})
	}
}

// TestExample_CustomAssertions demonstrates custom validation logic
func TestExample_CustomAssertions(t *testing.T) {
	t.Skip("This is an example test - skip by default")

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Custom validation function
	validateNetworkSecurity := func(t *testing.T, opts *terraform.Options) {
		publicAccess := terraform.Output(t, opts, "public_network_access_enabled")
		assert.Equal(t, "false", publicAccess, "Public network access should be disabled")

		defaultAction := terraform.Output(t, opts, "network_default_action")
		assert.Equal(t, "Deny", defaultAction, "Default network action should be Deny")
	}

	// Use custom validation
	validateNetworkSecurity(t, terraformOptions)
}

// BenchmarkExample_TerraformApply demonstrates benchmarking
func BenchmarkExample_TerraformApply(b *testing.B) {
	b.Skip("This is an example benchmark - skip by default")

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
	}

	// Setup
	terraform.Init(b, terraformOptions)

	b.ResetTimer() // Start timing after setup

	for i := 0; i < b.N; i++ {
		terraform.Apply(b, terraformOptions)
		terraform.Destroy(b, terraformOptions)
	}
}

// Helper function examples

// getTestTerraformOptions returns commonly used terraform options for tests
func getTestTerraformOptions(t *testing.T, resourceGroupName string) *terraform.Options {
	return terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"azurerm_resource_group_name":     resourceGroupName,
			"azurerm_resource_group_location": "Japan East",
		},
		NoColor: true,
	})
}

// validateResourceExists is a helper function to check if Azure resource exists
func validateResourceExists(t *testing.T, resourceName, resourceType string) {
	// This is a placeholder - implement actual Azure SDK checks
	assert.NotEmpty(t, resourceName, fmt.Sprintf("%s name should not be empty", resourceType))
}

// cleanupTestResources is a helper function for cleanup
func cleanupTestResources(t *testing.T, terraformOptions *terraform.Options) {
	t.Log("Starting cleanup...")
	_, err := terraform.DestroyE(t, terraformOptions)
	if err != nil {
		t.Logf("Warning: cleanup failed: %v", err)
		// Log but don't fail the test - cleanup issues shouldn't fail the test
	}
	t.Log("Cleanup completed")
}
