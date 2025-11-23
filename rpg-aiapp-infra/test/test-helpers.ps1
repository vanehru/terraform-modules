# Test Helpers - PowerShell Functions

function Show-Help {
    Write-Host "Available test commands:" -ForegroundColor Cyan
    Write-Host "  init              - Initialize Go modules" -ForegroundColor White
    Write-Host "  test              - Run main infrastructure test" -ForegroundColor White
    Write-Host "  test-module       - Run all module tests" -ForegroundColor White
    Write-Host "  test-integration  - Run integration tests" -ForegroundColor White
    Write-Host "  test-all          - Run all tests" -ForegroundColor White
    Write-Host "  test-function-app - Run Function App module test" -ForegroundColor White
    Write-Host "  test-key-vault    - Run Key Vault module test" -ForegroundColor White
    Write-Host "  test-sql          - Run SQL Database module test" -ForegroundColor White
    Write-Host "  test-openai       - Run OpenAI module test" -ForegroundColor White
    Write-Host "  clean             - Clean test cache" -ForegroundColor White
    Write-Host "  fmt               - Format Go code" -ForegroundColor White
    Write-Host "  test-with-log     - Run tests with logging" -ForegroundColor White
    Write-Host "  test-parallel     - Run tests in parallel" -ForegroundColor White
}

function Initialize {
    Write-Host "Initializing Go modules..." -ForegroundColor Green
    go mod download
    go mod tidy
    Write-Host "Done!" -ForegroundColor Green
}

function Test-Main {
    Write-Host "Running main infrastructure tests..." -ForegroundColor Green
    go test -v -timeout 90m -run TestRPGAIAppInfrastructure
}

function Test-Modules {
    Write-Host "Running module tests..." -ForegroundColor Green
    go test -v -timeout 30m -run "TestFunctionAppModule|TestKeyVaultModule|TestSQLDatabaseModule|TestOpenAIModule"
}

function Test-Integration {
    Write-Host "Running integration tests..." -ForegroundColor Green
    go test -v -timeout 60m -run TestIntegrationEndToEnd
}

function Test-All {
    Write-Host "Running all tests..." -ForegroundColor Green
    go test -v -timeout 120m
}

function Test-FunctionApp {
    Write-Host "Running Function App module tests..." -ForegroundColor Green
    go test -v -timeout 30m -run TestFunctionAppModule
}

function Test-KeyVault {
    Write-Host "Running Key Vault module tests..." -ForegroundColor Green
    go test -v -timeout 30m -run TestKeyVaultModule
}

function Test-Sql {
    Write-Host "Running SQL Database module tests..." -ForegroundColor Green
    go test -v -timeout 30m -run TestSQLDatabaseModule
}

function Test-OpenAI {
    Write-Host "Running OpenAI module tests..." -ForegroundColor Green
    go test -v -timeout 30m -run TestOpenAIModule
}

function Clean-TestCache {
    Write-Host "Cleaning test cache..." -ForegroundColor Green
    go clean -testcache
    Remove-Item -Path "test-results.log" -ErrorAction SilentlyContinue
    Write-Host "Done!" -ForegroundColor Green
}

function Format-Code {
    Write-Host "Formatting Go code..." -ForegroundColor Green
    go fmt ./...
    Write-Host "Done!" -ForegroundColor Green
}

function Test-WithLog {
    Write-Host "Running tests with logging..." -ForegroundColor Green
    go test -v -timeout 90m 2>&1 | Tee-Object -FilePath "test-results.log"
    Write-Host "Results saved to test-results.log" -ForegroundColor Green
}

function Test-Parallel {
    Write-Host "Running tests in parallel..." -ForegroundColor Green
    go test -v -timeout 90m -parallel 4
}

# Export functions as aliases for easier use
Set-Alias -Name init -Value Initialize
Set-Alias -Name test -Value Test-Main
Set-Alias -Name test-module -Value Test-Modules
Set-Alias -Name test-integration -Value Test-Integration
Set-Alias -Name test-all -Value Test-All
Set-Alias -Name test-function-app -Value Test-FunctionApp
Set-Alias -Name test-key-vault -Value Test-KeyVault
Set-Alias -Name test-sql -Value Test-Sql
Set-Alias -Name test-openai -Value Test-OpenAI
Set-Alias -Name clean -Value Clean-TestCache
Set-Alias -Name fmt -Value Format-Code
Set-Alias -Name test-with-log -Value Test-WithLog
Set-Alias -Name test-parallel -Value Test-Parallel

# Show help if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Show-Help
    Write-Host "`nUsage: . .\test-helpers.ps1  # Load functions into your session" -ForegroundColor Yellow
    Write-Host "Then run: test-function-app  # Or any other command" -ForegroundColor Yellow
}
