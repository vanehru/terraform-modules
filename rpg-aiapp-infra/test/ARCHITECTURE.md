# RPG AIApp Infrastructure Test Architecture

## Test Structure Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                      RPG AIApp Infrastructure                        │
│                         Terratest Suite                              │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                    ┌─────────────┴──────────────┐
                    │                            │
         ┌──────────▼────────┐        ┌─────────▼─────────┐
         │   Module Tests    │        │ Integration Tests │
         │   (15-30 min)     │        │   (45-60 min)     │
         └──────────┬────────┘        └─────────┬─────────┘
                    │                            │
    ┌───────────────┼────────────────┐          │
    │               │                │          │
┌───▼───┐      ┌────▼────┐     ┌────▼───┐  ┌───▼────────┐
│Function│      │Key Vault│     │   SQL  │  │  End-to-End│
│  App   │      │         │     │Database│  │ Integration│
└────────┘      └─────────┘     └────────┘  └────────────┘
┌────────┐
│ OpenAI │
└────────┘
                    │
         ┌──────────▼────────────┐
         │ Full Infrastructure   │
         │   Test (90-120 min)   │
         └───────────────────────┘
```

## Test Execution Flow

```
START
  │
  ├─► 1. Setup Phase
  │    ├─► Generate unique resource names
  │    ├─► Configure Terraform options
  │    └─► Set test variables
  │
  ├─► 2. Pre-Deployment
  │    ├─► Authenticate with Azure
  │    ├─► Verify prerequisites
  │    └─► Initialize Terraform
  │
  ├─► 3. Deployment Phase
  │    ├─► terraform init
  │    ├─► terraform plan
  │    └─► terraform apply
  │
  ├─► 4. Validation Phase
  │    ├─► Resource Existence Tests
  │    ├─► Configuration Tests
  │    ├─► Security Tests
  │    ├─► Integration Tests
  │    └─► Network Tests
  │
  ├─► 5. Cleanup Phase
  │    ├─► terraform destroy
  │    ├─► Verify deletion
  │    └─► Clean test artifacts
  │
  └─► END (PASS/FAIL)
```

## Component Dependencies

```
┌─────────────────────────────────────────────────────────────┐
│                    Resource Dependencies                     │
└─────────────────────────────────────────────────────────────┘

Resource Group
    │
    ├─► Virtual Network
    │       │
    │       ├─► app-subnet ──────────┐
    │       ├─► storage-subnet ──┐   │
    │       ├─► keyvault-subnet ─┼─┐ │
    │       ├─► database-subnet ─┼─┼─┼─┐
    │       ├─► openai-subnet ───┼─┼─┼─┼─┐
    │       └─► deployment-subnet│ │ │ │ │
    │                            │ │ │ │ │
    ├─► Function App ────────────┘ │ │ │ │
    │     └─► Storage Account ─────┘ │ │ │
    │           └─► Private Endpoint  │ │ │
    │                                 │ │ │
    ├─► Key Vault ───────────────────┘ │ │
    │     └─► Private Endpoint          │ │
    │                                   │ │
    ├─► SQL Database ──────────────────┘ │
    │     └─► Private Endpoint            │
    │                                     │
    ├─► Azure OpenAI ────────────────────┘
    │     └─► Private Endpoint
    │
    └─► Static Web App
```

## Test Coverage Matrix

```
┌──────────────────┬─────────┬────────────┬────────────┬───────────┐
│   Component      │ Exists  │   Config   │  Security  │Integration│
├──────────────────┼─────────┼────────────┼────────────┼───────────┤
│ Resource Group   │    ✓    │     ✓      │     ✓      │     -     │
│ Virtual Network  │    ✓    │     ✓      │     ✓      │     ✓     │
│ Subnets (6)      │    ✓    │     ✓      │     ✓      │     ✓     │
│ Function App     │    ✓    │     ✓      │     ✓      │     ✓     │
│ Storage Account  │    ✓    │     ✓      │     ✓      │     ✓     │
│ Key Vault        │    ✓    │     ✓      │     ✓      │     ✓     │
│ SQL Database     │    ✓    │     ✓      │     ✓      │     ✓     │
│ Azure OpenAI     │    ✓    │     ✓      │     ✓      │     ✓     │
│ Static Web App   │    ✓    │     ✓      │     -      │     ✓     │
│ Private Endpoints│    ✓    │     ✓      │     ✓      │     ✓     │
│ Managed Identity │    ✓    │     ✓      │     ✓      │     ✓     │
└──────────────────┴─────────┴────────────┴────────────┴───────────┘

Legend: ✓ = Tested, - = Not Applicable
```

## Test File Organization

```
test/
│
├── Main Tests
│   ├── rpg_aiapp_infra_test.go      [Full Infrastructure Test]
│   │   ├─► TestRPGAIAppInfrastructure
│   │   ├─► testResourceGroupExists
│   │   ├─► testVNetConfiguration
│   │   ├─► testSubnetConfiguration
│   │   ├─► testFunctionAppDeployment
│   │   ├─► testKeyVaultDeployment
│   │   ├─► testSQLDatabaseDeployment
│   │   ├─► testOpenAIDeployment
│   │   ├─► testStaticWebAppDeployment
│   │   ├─► testNetworkSecurity
│   │   └─► testPrivateEndpoints
│   │
│   └── integration_test.go           [Integration Test]
│       ├─► TestIntegrationEndToEnd
│       ├─► testFunctionAppKeyVaultIntegration
│       ├─► testKeyVaultSecretsIntegration
│       ├─► testPrivateEndpointsConnectivity
│       ├─► testStaticWebAppAccessibility
│       └─► testNetworkIsolation
│
├── Module Tests
│   ├── function_app_module_test.go  [Function App]
│   ├── key_vault_module_test.go     [Key Vault]
│   ├── sql_database_module_test.go  [SQL Database]
│   └── openai_module_test.go        [Azure OpenAI]
│
├── Documentation
│   ├── README.md                    [Complete Guide]
│   ├── QUICKSTART.md                [Quick Start]
│   ├── SUMMARY.md                   [Summary]
│   ├── COMMANDS.md                  [Command Reference]
│   └── ARCHITECTURE.md              [This File]
│
├── Configuration
│   ├── go.mod                       [Go Module]
│   ├── .gitignore                   [Git Ignore]
│   └── test-config.template.yml    [Config Template]
│
└── Automation
    ├── Makefile                     [Linux/Mac]
    ├── test-helpers.ps1             [Windows]
    └── examples_test.go             [Examples]
```

## CI/CD Pipeline Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Actions                         │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
  ┌─────▼──────┐                         ┌──────▼─────┐
  │   Trigger  │                         │  Validate  │
  ├────────────┤                         ├────────────┤
  │ • Push     │                         │ • tf fmt   │
  │ • PR       │                         │ • tf init  │
  │ • Manual   │                         │ • tf validate
  └─────┬──────┘                         └──────┬─────┘
        │                                       │
        └───────────────────┬───────────────────┘
                            │
                ┌───────────▼────────────┐
                │   Module Tests         │
                │   (Parallel)           │
                ├────────────────────────┤
                │ • Function App         │
                │ • Key Vault            │
                │ • SQL Database         │
                │ • OpenAI               │
                └───────────┬────────────┘
                            │
                ┌───────────▼────────────┐
                │  Integration Tests     │
                └───────────┬────────────┘
                            │
                ┌───────────▼────────────┐
                │ Full Infrastructure    │
                │ (main branch only)     │
                └───────────┬────────────┘
                            │
                ┌───────────▼────────────┐
                │   Upload Artifacts     │
                │   Send Notifications   │
                └────────────────────────┘
```

## Test Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        Test Input                            │
├─────────────────────────────────────────────────────────────┤
│ • Azure Credentials                                          │
│ • Test Configuration (region, SKUs, etc.)                    │
│ • Unique Resource Names (generated)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Terraform Apply                           │
├─────────────────────────────────────────────────────────────┤
│ Creates: Resource Group, VNet, Subnets, Function App, etc.  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                   Terraform Outputs                          │
├─────────────────────────────────────────────────────────────┤
│ • Resource IDs                                               │
│ • Connection Strings                                         │
│ • Endpoints                                                  │
│ • Keys and Secrets                                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Test Assertions                           │
├─────────────────────────────────────────────────────────────┤
│ • Resource existence validation                              │
│ • Configuration verification                                 │
│ • Security checks                                            │
│ • Integration validation                                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Test Results                              │
├─────────────────────────────────────────────────────────────┤
│ PASS: All assertions succeeded                               │
│ FAIL: One or more assertions failed                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 Terraform Destroy                            │
├─────────────────────────────────────────────────────────────┤
│ Removes: All created resources                               │
└─────────────────────────────────────────────────────────────┘
```

## Security Testing Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Validation                       │
└─────────────────────────────────────────────────────────────┘

Layer 1: Network Security
    ├─► Public access disabled
    ├─► Private endpoints configured
    ├─► Network ACLs enforced
    └─► VNet integration enabled

Layer 2: Identity & Access
    ├─► Managed identities enabled
    ├─► Access policies configured
    ├─► RBAC assignments correct
    └─► Service principals secured

Layer 3: Data Protection
    ├─► TLS 1.2+ enforced
    ├─► Encryption at rest
    ├─► Encryption in transit
    └─► Secrets in Key Vault

Layer 4: Compliance
    ├─► Azure Policy compliance
    ├─► Required tags present
    ├─► Naming conventions
    └─► Resource locks
```

## Cost Breakdown

```
┌────────────────────────────────────────────────────────────┐
│              Test Cost Estimation (per run)                │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Function App (P1v2)     ~$0.10/hour  ███░░░░░░  30%      │
│  SQL Database (Basic)    ~$5/month    ████████░░  40%     │
│  Azure OpenAI (S0)       ~$0.002/1K   ██░░░░░░░░  15%     │
│  Storage Account         ~$0.02/GB    █░░░░░░░░░  10%     │
│  Key Vault              ~$0.03/10K    █░░░░░░░░░   5%     │
│                                                            │
│  Total per run: $3-5 USD                                  │
│  Duration: 90-120 minutes                                 │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## Performance Characteristics

```
┌──────────────────────┬──────────┬──────────┬──────────────┐
│   Test Type          │ Duration │   Cost   │  Resources   │
├──────────────────────┼──────────┼──────────┼──────────────┤
│ Function App Module  │  15-30m  │  $1-2    │     3-5      │
│ Key Vault Module     │  15-30m  │  $1-2    │     2-3      │
│ SQL Database Module  │  15-30m  │  $1-2    │     2-3      │
│ OpenAI Module        │  15-30m  │  $1-2    │     2-3      │
│ Integration Test     │  45-60m  │  $2-3    │    10+       │
│ Full Infrastructure  │ 90-120m  │  $3-5    │    20+       │
├──────────────────────┼──────────┼──────────┼──────────────┤
│ Parallel Modules     │  30-45m  │  $4-8    │    10-15     │
│ All Tests Sequential │  3-4h    │ $10-15   │    20+       │
└──────────────────────┴──────────┴──────────┴──────────────┘
```

## Best Practices Implementation

```
✓ Modular Design
  └─► Each module tested independently
  
✓ Parallel Execution
  └─► Multiple tests run simultaneously
  
✓ Automatic Cleanup
  └─► Resources deleted after each test
  
✓ Unique Naming
  └─► No resource conflicts
  
✓ Retry Logic
  └─► Handle eventual consistency
  
✓ Comprehensive Logging
  └─► Debug-friendly output
  
✓ Cost Optimization
  └─► Minimal resource SKUs for testing
  
✓ Security First
  └─► Validate all security controls
```

## Integration Points

```
┌─────────────────────────────────────────────────────────┐
│            Component Integration Testing                │
└─────────────────────────────────────────────────────────┘

Function App ─────► Key Vault
    ↓                   ↓
    └─► Managed Identity has access to secrets
    
Function App ─────► Storage Account
    ↓                   ↓
    └─► VNet Integration allows private access

Function App ─────► SQL Database
    ↓                   ↓
    └─► Connection string from Key Vault

Function App ─────► Azure OpenAI
    ↓                   ↓
    └─► API key from Key Vault

Static Web App ───► Function App
    ↓                   ↓
    └─► CORS configured for frontend access
```

## Error Handling Strategy

```
Test Execution
    │
    ├─► Retryable Errors (retry with backoff)
    │   ├─► Network timeouts
    │   ├─► Resource not ready
    │   └─► Eventual consistency
    │
    ├─► Fatal Errors (fail immediately)
    │   ├─► Authentication failure
    │   ├─► Quota exceeded
    │   └─► Invalid configuration
    │
    └─► Cleanup Errors (log but continue)
        ├─► Destroy timeout
        ├─► Resource already deleted
        └─► State file issues
```

## Future Enhancements

```
Planned Improvements:
├─► Chaos Engineering Tests
├─► Performance Benchmarks
├─► Load Testing
├─► Disaster Recovery Tests
├─► Multi-Region Deployment
├─► Blue-Green Deployment Tests
├─► Canary Deployment Tests
└─► Custom Metrics & Dashboards
```

---

This architecture ensures comprehensive testing of the RPG AIApp infrastructure with optimal performance, cost efficiency, and reliability.
