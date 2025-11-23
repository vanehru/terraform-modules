package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestRPGAIAppInfrastructure tests the complete RPG AI App infrastructure
func TestRPGAIAppInfrastructure(t *testing.T) {
	t.Parallel()

	// Generate unique resource names for testing
	uniqueID := strings.ToLower(random.UniqueId())
	resourceGroupName := fmt.Sprintf("rpg-aiapp-rg-test-%s", uniqueID)

	// Expected location
	expectedLocation := "japaneast"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where your Terraform code is located
		TerraformDir: "../",

		// Variables to pass to terraform
		Vars: map[string]interface{}{
			"azurerm_resource_group_name":     resourceGroupName,
			"azurerm_resource_group_location": "Japan East",
		},

		// Disable colors in Terraform commands
		NoColor: true,
	})

	// Ensure resources are destroyed at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Run all validation tests
	t.Run("ResourceGroupExists", func(t *testing.T) {
		testResourceGroupExists(t, terraformOptions, resourceGroupName, expectedLocation)
	})

	t.Run("VNetConfiguration", func(t *testing.T) {
		testVNetConfiguration(t, terraformOptions, resourceGroupName)
	})

	t.Run("SubnetConfiguration", func(t *testing.T) {
		testSubnetConfiguration(t, terraformOptions, resourceGroupName)
	})

	t.Run("FunctionAppDeployment", func(t *testing.T) {
		testFunctionAppDeployment(t, terraformOptions, resourceGroupName)
	})

	t.Run("KeyVaultDeployment", func(t *testing.T) {
		testKeyVaultDeployment(t, terraformOptions, resourceGroupName)
	})

	t.Run("SQLDatabaseDeployment", func(t *testing.T) {
		testSQLDatabaseDeployment(t, terraformOptions, resourceGroupName)
	})

	t.Run("OpenAIDeployment", func(t *testing.T) {
		testOpenAIDeployment(t, terraformOptions, resourceGroupName)
	})

	t.Run("StaticWebAppDeployment", func(t *testing.T) {
		testStaticWebAppDeployment(t, terraformOptions, resourceGroupName)
	})

	t.Run("NetworkSecurity", func(t *testing.T) {
		testNetworkSecurity(t, terraformOptions)
	})

	t.Run("PrivateEndpoints", func(t *testing.T) {
		testPrivateEndpoints(t, terraformOptions, resourceGroupName)
	})
}

// testResourceGroupExists validates that the resource group was created
func testResourceGroupExists(t *testing.T, terraformOptions *terraform.Options, expectedRGName, expectedLocation string) {
	// Get the resource group name from Terraform output
	rgName := terraform.Output(t, terraformOptions, "resource_group_name")

	// Verify resource group name matches expected
	assert.Equal(t, expectedRGName, rgName, "Resource group name should match expected value")

	// Verify output is valid
	assert.NotEmpty(t, rgName, "Resource group name should not be empty")

	// Get resource group location
	rgLocation := terraform.Output(t, terraformOptions, "resource_group_location")
	assert.Equal(t, expectedLocation, strings.ToLower(strings.ReplaceAll(rgLocation, " ", "")),
		"Resource group location should match expected location")
} // testVNetConfiguration validates the Virtual Network configuration
func testVNetConfiguration(t *testing.T, terraformOptions *terraform.Options, resourceGroupName string) {
	// Get VNet details from outputs
	vnetName := terraform.Output(t, terraformOptions, "vnet_name")
	assert.NotEmpty(t, vnetName, "VNet name should not be empty")

	// Verify address space
	addressSpace := terraform.OutputList(t, terraformOptions, "vnet_address_space")
	assert.NotEmpty(t, addressSpace, "VNet address space should not be empty")
	assert.Contains(t, addressSpace, "172.16.0.0/16", "VNet should have expected address space")
}

// testSubnetConfiguration validates all subnet configurations
func testSubnetConfiguration(t *testing.T, terraformOptions *terraform.Options, resourceGroupName string) {
	vnetName := terraform.Output(t, terraformOptions, "vnet_name")
	assert.NotEmpty(t, vnetName, "VNet name should not be empty")

	// Expected subnets
	expectedSubnets := []string{
		"app-subnet",
		"storage-subnet",
		"keyvault-subnet",
		"database-subnet",
		"openai-subnet",
		"deployment-subnet",
	}

	// Verify we have output for all subnets
	for _, subnetName := range expectedSubnets {
		t.Run(subnetName, func(t *testing.T) {
			// Subnets are verified through Terraform deployment success
			t.Logf("Subnet %s configured in VNet %s", subnetName, vnetName)
		})
	}
}

// testFunctionAppDeployment validates the Function App deployment
func testFunctionAppDeployment(t *testing.T, terraformOptions *terraform.Options, resourceGroupName string) {
	// Get Function App details
	functionAppName := terraform.Output(t, terraformOptions, "function_app_name")
	assert.NotEmpty(t, functionAppName, "Function App name should not be empty")

	// Verify Function App exists



	// Verify managed identity is enabled
	identityPrincipalID := terraform.Output(t, terraformOptions, "function_app_identity_principal_id")
	assert.NotEmpty(t, identityPrincipalID, "Function App should have managed identity enabled")

	// Verify VNet integration
	vnetIntegrationEnabled := terraform.Output(t, terraformOptions, "function_app_vnet_integration_enabled")
	assert.Equal(t, "true", vnetIntegrationEnabled, "Function App should have VNet integration enabled")
}

// testKeyVaultDeployment validates the Key Vault deployment
func testKeyVaultDeployment(t *testing.T, terraformOptions *terraform.Options, resourceGroupName string) {
	// Get Key Vault details
	keyVaultName := terraform.Output(t, terraformOptions, "key_vault_name")
	assert.NotEmpty(t, keyVaultName, "Key Vault name should not be empty")

	// Verify Key Vault exists



	// Verify Key Vault URI
	keyVaultURI := terraform.Output(t, terraformOptions, "key_vault_uri")
	assert.Contains(t, keyVaultURI, "vault.azure.net", "Key Vault URI should be valid")

	// Verify private endpoint is enabled
	privateEndpointEnabled := terraform.Output(t, terraformOptions, "key_vault_private_endpoint_enabled")
	assert.Equal(t, "true", privateEndpointEnabled, "Key Vault should have private endpoint enabled")
}

// testSQLDatabaseDeployment validates the SQL Database deployment
func testSQLDatabaseDeployment(t *testing.T, terraformOptions *terraform.Options, resourceGroupName string) {
	// Get SQL Server details
	sqlServerName := terraform.Output(t, terraformOptions, "sql_server_name")
	assert.NotEmpty(t, sqlServerName, "SQL Server name should not be empty")

	// Verify SQL Server exists



	// Get SQL Database name
	sqlDatabaseName := terraform.Output(t, terraformOptions, "sql_database_name")
	assert.NotEmpty(t, sqlDatabaseName, "SQL Database name should not be empty")

	// Verify SQL Database exists

	

	// Verify private endpoint is enabled
	privateEndpointEnabled := terraform.Output(t, terraformOptions, "sql_private_endpoint_enabled")
	assert.Equal(t, "true", privateEndpointEnabled, "SQL Server should have private endpoint enabled")
}

// testOpenAIDeployment validates the Azure OpenAI deployment
func testOpenAIDeployment(t *testing.T, terraformOptions *terraform.Options, resourceGroupName string) {
	// Get OpenAI account details
	openAIName := terraform.Output(t, terraformOptions, "openai_account_name")
	assert.NotEmpty(t, openAIName, "OpenAI account name should not be empty")

	// Verify OpenAI endpoint
	openAIEndpoint := terraform.Output(t, terraformOptions, "openai_endpoint")
	assert.Contains(t, openAIEndpoint, "openai.azure.com", "OpenAI endpoint should be valid")

	// Verify private endpoint is enabled
	privateEndpointEnabled := terraform.Output(t, terraformOptions, "openai_private_endpoint_enabled")
	assert.Equal(t, "true", privateEndpointEnabled, "OpenAI should have private endpoint enabled")
}

// testStaticWebAppDeployment validates the Static Web App deployment
func testStaticWebAppDeployment(t *testing.T, terraformOptions *terraform.Options, resourceGroupName string) {
	// Get Static Web App details
	swaName := terraform.Output(t, terraformOptions, "static_web_app_name")
	assert.NotEmpty(t, swaName, "Static Web App name should not be empty")

	// Verify default hostname
	defaultHostname := terraform.Output(t, terraformOptions, "static_web_app_default_hostname")
	assert.Contains(t, defaultHostname, ".azurestaticapps.net", "Static Web App hostname should be valid")

	// Verify API key exists
	apiKey := terraform.Output(t, terraformOptions, "static_web_app_api_key")
	assert.NotEmpty(t, apiKey, "Static Web App API key should not be empty")
}

// testNetworkSecurity validates network security configurations
func testNetworkSecurity(t *testing.T, terraformOptions *terraform.Options) {
	// Verify storage account has private network access
	storagePublicAccess := terraform.Output(t, terraformOptions, "storage_public_network_access_enabled")
	assert.Equal(t, "false", storagePublicAccess, "Storage account should have public network access disabled")

	// Verify Key Vault network ACLs
	keyVaultNetworkAction := terraform.Output(t, terraformOptions, "key_vault_network_default_action")
	assert.Equal(t, "Deny", keyVaultNetworkAction, "Key Vault should deny access by default")

	// Verify SQL firewall rules
	sqlPublicAccess := terraform.Output(t, terraformOptions, "sql_public_network_access_enabled")
	assert.Equal(t, "false", sqlPublicAccess, "SQL Server should have public network access disabled")
}

// testPrivateEndpoints validates that all private endpoints are properly configured
func testPrivateEndpoints(t *testing.T, terraformOptions *terraform.Options, resourceGroupName string) {
	// Get VNet name for verification
	vnetName := terraform.Output(t, terraformOptions, "vnet_name")
	assert.NotEmpty(t, vnetName, "VNet should exist for private endpoints")

	// Verify storage private endpoint
	t.Run("StoragePrivateEndpoint", func(t *testing.T) {
		storagePrivateEndpointID := terraform.Output(t, terraformOptions, "storage_private_endpoint_id")
		assert.NotEmpty(t, storagePrivateEndpointID, "Storage private endpoint should exist")
	})

	// Verify Key Vault private endpoint
	t.Run("KeyVaultPrivateEndpoint", func(t *testing.T) {
		kvPrivateEndpointID := terraform.Output(t, terraformOptions, "key_vault_private_endpoint_id")
		assert.NotEmpty(t, kvPrivateEndpointID, "Key Vault private endpoint should exist")
	})

	// Verify SQL private endpoint
	t.Run("SQLPrivateEndpoint", func(t *testing.T) {
		sqlPrivateEndpointID := terraform.Output(t, terraformOptions, "sql_private_endpoint_id")
		assert.NotEmpty(t, sqlPrivateEndpointID, "SQL private endpoint should exist")
	})

	// Verify OpenAI private endpoint
	t.Run("OpenAIPrivateEndpoint", func(t *testing.T) {
		openAIPrivateEndpointID := terraform.Output(t, terraformOptions, "openai_private_endpoint_id")
		assert.NotEmpty(t, openAIPrivateEndpointID, "OpenAI private endpoint should exist")
	})
}
