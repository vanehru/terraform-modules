package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestOpenAIModule tests the Azure OpenAI module independently
func TestOpenAIModule(t *testing.T) {
	t.Skip("Module tests require pre-existing resource group. Use TestRPGAIAppInfrastructure for full infrastructure testing.")

	t.Parallel()

	uniqueID := strings.ToLower(random.UniqueId())
	resourceGroupName := fmt.Sprintf("test-openai-rg-%s", uniqueID)
	openAIName := fmt.Sprintf("testopenai%s", uniqueID)
	location := "Japan East"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/openai",
		Vars: map[string]interface{}{
			"openai_account_name":           openAIName,
			"location":                      location,
			"resource_group_name":           resourceGroupName,
			"sku_name":                      "S0",
			"public_network_access_enabled": true, // For testing
			"custom_subdomain_name":         openAIName,
			"deployments": []map[string]interface{}{
				{
					"name":          "gpt-35-turbo",
					"model_format":  "OpenAI",
					"model_name":    "gpt-35-turbo",
					"model_version": "0613",
					"scale_type":    "Standard",
				},
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test OpenAI account name
	t.Run("OpenAIAccountName", func(t *testing.T) {
		actualName := terraform.Output(t, terraformOptions, "openai_account_name")
		assert.Equal(t, openAIName, actualName)
	})

	// Test OpenAI endpoint
	t.Run("OpenAIEndpoint", func(t *testing.T) {
		endpoint := terraform.Output(t, terraformOptions, "openai_endpoint")
		assert.Contains(t, endpoint, openAIName)
		assert.Contains(t, endpoint, "openai.azure.com")
	})

	// Test primary key exists
	t.Run("PrimaryKeyExists", func(t *testing.T) {
		primaryKey := terraform.Output(t, terraformOptions, "openai_primary_key")
		assert.NotEmpty(t, primaryKey, "Primary key should exist")
	})

	// Test deployment IDs
	t.Run("DeploymentsCreated", func(t *testing.T) {
		deploymentIDs := terraform.OutputMap(t, terraformOptions, "deployment_ids")
		assert.Contains(t, deploymentIDs, "gpt-35-turbo", "GPT-3.5 deployment should be created")
	})
}
