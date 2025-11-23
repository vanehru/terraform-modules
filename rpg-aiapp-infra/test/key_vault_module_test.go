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

// TestKeyVaultModule tests the Key Vault module independently
func TestKeyVaultModule(t *testing.T) {
	t.Parallel()

	uniqueID := strings.ToLower(random.UniqueId())
	resourceGroupName := fmt.Sprintf("test-kv-rg-%s", uniqueID)
	keyVaultName := fmt.Sprintf("testkv%s", uniqueID)
	location := "Japan East"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/key-vault",
		Vars: map[string]interface{}{
			"key_vault_name":              keyVaultName,
			"location":                    location,
			"resource_group_name":         resourceGroupName,
			"tenant_id":                   "00000000-0000-0000-0000-000000000000", // Use actual tenant ID
			"sku_name":                    "standard",
			"purge_protection_enabled":    false,
			"network_acls_default_action": "Allow", // For testing
			"network_acls_bypass":         "AzureServices",
			"secrets": map[string]interface{}{
				"test-secret": "test-value",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test Key Vault exists
	t.Run("KeyVaultExists", func(t *testing.T) {
		actualKVName := terraform.Output(t, terraformOptions, "key_vault_name")
		assert.Equal(t, keyVaultName, actualKVName)

		exists := azure.KeyVaultExists(t, actualKVName, resourceGroupName, "")
		assert.True(t, exists, "Key Vault should exist")
	})

	// Test Key Vault URI
	t.Run("KeyVaultURI", func(t *testing.T) {
		kvURI := terraform.Output(t, terraformOptions, "key_vault_uri")
		assert.Contains(t, kvURI, keyVaultName)
		assert.Contains(t, kvURI, "vault.azure.net")
	})

	// Test secrets are created
	t.Run("SecretsCreated", func(t *testing.T) {
		secretIDs := terraform.OutputMap(t, terraformOptions, "secret_ids")
		assert.Contains(t, secretIDs, "test-secret", "Secret should be created")
	})
}
