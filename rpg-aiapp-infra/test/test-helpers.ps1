# Test Helpers

# Available Makefile targets
default:
	@Get-Content Makefile | Select-String "^[a-zA-Z]" | ForEach-Object { Write-Host $_ }

# Initialize Go modules
init:
	Write-Host "Initializing Go modules..." -ForegroundColor Green
	go mod download
	go mod tidy
	Write-Host "Done!" -ForegroundColor Green

# Run main infrastructure test
test:
	Write-Host "Running main infrastructure tests..." -ForegroundColor Green
	go test -v -timeout 90m -run TestRPGAIAppInfrastructure

# Run all module tests
test-module:
	Write-Host "Running module tests..." -ForegroundColor Green
	go test -v -timeout 30m -run "TestFunctionAppModule|TestKeyVaultModule|TestSQLDatabaseModule|TestOpenAIModule"

# Run integration tests
test-integration:
	Write-Host "Running integration tests..." -ForegroundColor Green
	go test -v -timeout 60m -run TestIntegrationEndToEnd

# Run all tests
test-all:
	Write-Host "Running all tests..." -ForegroundColor Green
	go test -v -timeout 120m

# Run Function App module tests
test-function-app:
	Write-Host "Running Function App module tests..." -ForegroundColor Green
	go test -v -timeout 30m -run TestFunctionAppModule

# Run Key Vault module tests
test-key-vault:
	Write-Host "Running Key Vault module tests..." -ForegroundColor Green
	go test -v -timeout 30m -run TestKeyVaultModule

# Run SQL Database module tests
test-sql:
	Write-Host "Running SQL Database module tests..." -ForegroundColor Green
	go test -v -timeout 30m -run TestSQLDatabaseModule

# Run OpenAI module tests
test-openai:
	Write-Host "Running OpenAI module tests..." -ForegroundColor Green
	go test -v -timeout 30m -run TestOpenAIModule

# Clean test cache
clean:
	Write-Host "Cleaning test cache..." -ForegroundColor Green
	go clean -testcache
	Remove-Item -Path "test-results.log" -ErrorAction SilentlyContinue
	Write-Host "Done!" -ForegroundColor Green

# Format code
fmt:
	Write-Host "Formatting Go code..." -ForegroundColor Green
	go fmt ./...
	Write-Host "Done!" -ForegroundColor Green

# Run tests with output to file
test-with-log:
	Write-Host "Running tests with logging..." -ForegroundColor Green
	go test -v -timeout 90m 2>&1 | Tee-Object -FilePath "test-results.log"
	Write-Host "Results saved to test-results.log" -ForegroundColor Green

# Run tests in parallel
test-parallel:
	Write-Host "Running tests in parallel..." -ForegroundColor Green
	go test -v -timeout 90m -parallel 4
