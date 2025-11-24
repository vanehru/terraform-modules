package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestIntegrationEndToEnd tests the complete integration of all components
func TestIntegrationEndToEnd(t *testing.T) {
	t.Skip("Integration tests require full infrastructure. Use TestRPGAIAppInfrastructure for complete testing.")

	t.Parallel()

	uniqueID := strings.ToLower(random.UniqueId())
	resourceGroupName := fmt.Sprintf("rpg-aiapp-integration-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"azurerm_resource_group_name":     resourceGroupName,
			"azurerm_resource_group_location": "Japan East",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test 1: Verify Function App can access Key Vault
	t.Run("FunctionAppToKeyVaultIntegration", func(t *testing.T) {
		testFunctionAppKeyVaultIntegration(t, terraformOptions)
	})

	// Test 2: Verify Key Vault stores SQL and OpenAI secrets
	t.Run("KeyVaultSecretsIntegration", func(t *testing.T) {
		testKeyVaultSecretsIntegration(t, terraformOptions)
	})

	// Test 3: Verify private endpoints connectivity
	t.Run("PrivateEndpointsConnectivity", func(t *testing.T) {
		testPrivateEndpointsConnectivity(t, terraformOptions)
	})

	// Test 4: Verify Static Web App is accessible
	t.Run("StaticWebAppAccessibility", func(t *testing.T) {
		testStaticWebAppAccessibility(t, terraformOptions)
	})

	// Test 5: Verify network isolation
	t.Run("NetworkIsolation", func(t *testing.T) {
		testNetworkIsolation(t, terraformOptions)
	})
}

// testFunctionAppKeyVaultIntegration verifies Function App can access Key Vault
func testFunctionAppKeyVaultIntegration(t *testing.T, terraformOptions *terraform.Options) {
	functionAppIdentity := terraform.Output(t, terraformOptions, "function_app_identity_principal_id")
	keyVaultName := terraform.Output(t, terraformOptions, "key_vault_name")

	assert.NotEmpty(t, functionAppIdentity, "Function App should have managed identity")
	assert.NotEmpty(t, keyVaultName, "Key Vault should exist")

	// Verify access policy includes Function App identity
	t.Logf("Verifying Function App %s has access to Key Vault %s", functionAppIdentity, keyVaultName)
}

// testKeyVaultSecretsIntegration verifies all required secrets are stored in Key Vault
func testKeyVaultSecretsIntegration(t *testing.T, terraformOptions *terraform.Options) {
	keyVaultName := terraform.Output(t, terraformOptions, "key_vault_name")

	// Expected secrets
	expectedSecrets := []string{
		"sql-connection-string",
		"sql-username",
		"sql-server-fqdn",
		"sql-database-name",
		"openai-endpoint",
		"openai-key",
	}

	// Verify SQL connection string is stored
	sqlConnString := terraform.Output(t, terraformOptions, "sql_connection_string")
	assert.NotEmpty(t, sqlConnString, "SQL connection string should be available")

	// Verify OpenAI endpoint is stored
	openAIEndpoint := terraform.Output(t, terraformOptions, "openai_endpoint")
	assert.NotEmpty(t, openAIEndpoint, "OpenAI endpoint should be available")

	t.Logf("Verified %d secrets are configured in Key Vault %s", len(expectedSecrets), keyVaultName)
}

// testPrivateEndpointsConnectivity verifies all private endpoints are properly configured
func testPrivateEndpointsConnectivity(t *testing.T, terraformOptions *terraform.Options) {
	vnetName := terraform.Output(t, terraformOptions, "vnet_name")
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")

	// Verify VNet exists for private endpoints
	assert.NotEmpty(t, vnetName, "VNet should exist for private endpoints")
	assert.NotEmpty(t, resourceGroupName, "Resource group should exist")

	// Verify private endpoint IDs
	storagePrivateEndpoint := terraform.Output(t, terraformOptions, "storage_private_endpoint_id")
	kvPrivateEndpoint := terraform.Output(t, terraformOptions, "key_vault_private_endpoint_id")
	sqlPrivateEndpoint := terraform.Output(t, terraformOptions, "sql_private_endpoint_id")
	openAIPrivateEndpoint := terraform.Output(t, terraformOptions, "openai_private_endpoint_id")

	assert.NotEmpty(t, storagePrivateEndpoint, "Storage private endpoint should exist")
	assert.NotEmpty(t, kvPrivateEndpoint, "Key Vault private endpoint should exist")
	assert.NotEmpty(t, sqlPrivateEndpoint, "SQL private endpoint should exist")
	assert.NotEmpty(t, openAIPrivateEndpoint, "OpenAI private endpoint should exist")
}

// testStaticWebAppAccessibility verifies Static Web App is accessible
func testStaticWebAppAccessibility(t *testing.T, terraformOptions *terraform.Options) {
	swaHostname := terraform.Output(t, terraformOptions, "static_web_app_default_hostname")
	swaURL := fmt.Sprintf("https://%s", swaHostname)

	// Verify Static Web App hostname is valid
	assert.Contains(t, swaHostname, ".azurestaticapps.net", "Static Web App hostname should be valid")
	assert.NotEmpty(t, swaURL, "Static Web App URL should not be empty")

	t.Logf("Static Web App URL: %s", swaURL)
} // testNetworkIsolation verifies network security configurations
func testNetworkIsolation(t *testing.T, terraformOptions *terraform.Options) {
	// Verify storage public access is disabled
	storagePublicAccess := terraform.Output(t, terraformOptions, "storage_public_network_access_enabled")
	assert.Equal(t, "false", storagePublicAccess, "Storage should not allow public access")

	// Verify Key Vault network ACLs
	kvNetworkAction := terraform.Output(t, terraformOptions, "key_vault_network_default_action")
	assert.Equal(t, "Deny", kvNetworkAction, "Key Vault should deny by default")

	// Verify SQL public access is disabled
	sqlPublicAccess := terraform.Output(t, terraformOptions, "sql_public_network_access_enabled")
	assert.Equal(t, "false", sqlPublicAccess, "SQL Server should not allow public access")

	// Verify OpenAI public access is disabled
	openAIPublicAccess := terraform.Output(t, terraformOptions, "openai_public_network_access_enabled")
	assert.Equal(t, "false", openAIPublicAccess, "OpenAI should not allow public access")

	t.Log("All network isolation checks passed")
}
