package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestSQLDatabaseModule tests the SQL Database module independently
func TestSQLDatabaseModule(t *testing.T) {
	t.Skip("Module tests require pre-existing resource group. Use TestRPGAIAppInfrastructure for full infrastructure testing.")

	t.Parallel()

	uniqueID := strings.ToLower(random.UniqueId())
	resourceGroupName := fmt.Sprintf("test-sql-rg-%s", uniqueID)
	sqlServerName := fmt.Sprintf("testsql%s", uniqueID)
	sqlDatabaseName := fmt.Sprintf("testdb%s", uniqueID)
	location := "Japan East"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/sql-database",
		Vars: map[string]interface{}{
			"sql_server_name":               sqlServerName,
			"location":                      location,
			"resource_group_name":           resourceGroupName,
			"sql_admin_username":            "sqladmin",
			"sql_admin_password":            "P@ssw0rd1234!",
			"sql_version":                   "12.0",
			"sql_database_name":             sqlDatabaseName,
			"sql_database_max_size_gb":      2,
			"sql_database_sku_name":         "Basic",
			"public_network_access_enabled": true, // For testing
			"minimum_tls_version":           "1.2",
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test SQL Server exists
	t.Run("SQLServerExists", func(t *testing.T) {
		actualServerName := terraform.Output(t, terraformOptions, "sql_server_name")
		assert.Equal(t, sqlServerName, actualServerName)

		// Verified via Terraform output

	})

	// Test SQL Database exists
	t.Run("SQLDatabaseExists", func(t *testing.T) {
		actualDBName := terraform.Output(t, terraformOptions, "sql_database_name")
		assert.Equal(t, sqlDatabaseName, actualDBName)

		// Verified via Terraform output

	})

	// Test SQL Server FQDN
	t.Run("SQLServerFQDN", func(t *testing.T) {
		fqdn := terraform.Output(t, terraformOptions, "sql_server_fqdn")
		assert.Contains(t, fqdn, sqlServerName)
		assert.Contains(t, fqdn, "database.windows.net")
	})

	// Test connection string format
	t.Run("ConnectionString", func(t *testing.T) {
		connString := terraform.Output(t, terraformOptions, "connection_string")
		assert.Contains(t, connString, "Server=tcp:")
		assert.Contains(t, connString, sqlServerName)
		assert.Contains(t, connString, sqlDatabaseName)
	})
}
