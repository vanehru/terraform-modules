package test

import (
	"database/sql"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	_ "github.com/denisenkom/go-mssqldb"
)

func TestSQLDatabaseConnectivity(t *testing.T) {
	terraformOptions := &terraform.Options{
		TerraformDir: "./",
	}

	connectionString := terraform.Output(t, terraformOptions, "connection_string")
	
	db, err := sql.Open("sqlserver", connectionString)
	assert.NoError(t, err)
	defer db.Close()

	// Retry connection
	var connected bool
	for i := 0; i < 5; i++ {
		if err := db.Ping(); err == nil {
			connected = true
			break
		}
		time.Sleep(10 * time.Second)
	}
	assert.True(t, connected)

	// Test CRUD operations
	_, err = db.Exec("CREATE TABLE test_table (id INT PRIMARY KEY, name NVARCHAR(50))")
	assert.NoError(t, err)

	_, err = db.Exec("INSERT INTO test_table VALUES (1, 'test')")
	assert.NoError(t, err)

	var name string
	err = db.QueryRow("SELECT name FROM test_table WHERE id = 1").Scan(&name)
	assert.NoError(t, err)
	assert.Equal(t, "test", name)
}