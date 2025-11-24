.PHONY: help init test test-module test-integration test-all clean fmt lint

# Default target
help:
	@echo "Available targets:"
	@echo "  init              - Initialize Go modules and download dependencies"
	@echo "  test              - Run main infrastructure tests"
	@echo "  test-module       - Run all module-specific tests"
	@echo "  test-integration  - Run integration tests"
	@echo "  test-all          - Run all tests"
	@echo "  test-function-app - Run Function App module tests"
	@echo "  test-key-vault    - Run Key Vault module tests"
	@echo "  test-sql          - Run SQL Database module tests"
	@echo "  test-openai       - Run OpenAI module tests"
	@echo "  clean             - Clean test cache and temporary files"
	@echo "  fmt               - Format Go code"
	@echo "  lint              - Run Go linter"

# Initialize and download dependencies
init:
	@echo "Initializing Go modules..."
	go mod download
	go mod tidy
	@echo "Done!"

# Run main infrastructure test
test:
	@echo "Running main infrastructure tests..."
	go test -v -timeout 90m -run TestRPGAIAppInfrastructure

# Run all module tests
test-module:
	@echo "Running module tests..."
	go test -v -timeout 30m -run "TestFunctionAppModule|TestKeyVaultModule|TestSQLDatabaseModule|TestOpenAIModule"

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	go test -v -timeout 60m -run TestIntegrationEndToEnd

# Run all tests
test-all:
	@echo "Running all tests..."
	go test -v -timeout 120m

# Run Function App module tests
test-function-app:
	@echo "Running Function App module tests..."
	go test -v -timeout 30m -run TestFunctionAppModule

# Run Key Vault module tests
test-key-vault:
	@echo "Running Key Vault module tests..."
	go test -v -timeout 30m -run TestKeyVaultModule

# Run SQL Database module tests
test-sql:
	@echo "Running SQL Database module tests..."
	go test -v -timeout 30m -run TestSQLDatabaseModule

# Run OpenAI module tests
test-openai:
	@echo "Running OpenAI module tests..."
	go test -v -timeout 30m -run TestOpenAIModule

# Clean test cache
clean:
	@echo "Cleaning test cache..."
	go clean -testcache
	rm -f test-results.log
	@echo "Done!"

# Format code
fmt:
	@echo "Formatting Go code..."
	go fmt ./...
	@echo "Done!"

# Run linter
lint:
	@echo "Running golangci-lint..."
	golangci-lint run
	@echo "Done!"

# Run tests with coverage
coverage:
	@echo "Running tests with coverage..."
	go test -v -timeout 90m -coverprofile=coverage.out
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Run tests in parallel
test-parallel:
	@echo "Running tests in parallel..."
	go test -v -timeout 90m -parallel 4
