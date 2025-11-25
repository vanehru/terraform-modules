# Design Document

## Overview

This design document outlines the enhancements to an existing Azure infrastructure for an AI-powered RPG gaming application. The infrastructure currently includes Static Web App, Function App, Key Vault, SQL Database, Azure OpenAI, and supporting network components. The design focuses on:

1. **Security Enhancement**: Implementing private endpoints and network isolation where cost-effective
2. **Integration Validation**: Ensuring seamless connectivity between all services
3. **Reusability**: Making the infrastructure deployable across multiple subscriptions
4. **Cost Optimization**: Balancing security with budget constraints (avoiding premium-only features where possible)

The infrastructure follows a defense-in-depth approach with multiple security layers: VNet isolation, private endpoints, managed identities, network ACLs, and secret management.

## Architecture

### High-Level Architecture

```
Internet
   ↓
┌─────────────────────┐
│  Static Web App     │ (Public - Frontend)
│  (Standard SKU)     │
└──────────┬──────────┘
           │ Linked Backend API
           ↓
╔══════════════════════════════════════╗
║   Azure Virtual Network              ║
║   (172.16.0.0/16)                   ║
║                                      ║
║  ┌────────────────────────────────┐ ║
║  │  App Subnet (172.16.1.0/24)    │ ║
║  │  ┌──────────────────────────┐  │ ║
║  │  │  Function App            │  │ ║
║  │  │  (VNet Integrated)       │  │ ║
║  │  │  + Managed Identity      │  │ ║
║  │  └──────────────────────────┘  │ ║
║  └────────────────────────────────┘ ║
║           │                          ║
║           │ Private Network          ║
║           ↓                          ║
║  ┌────────┴─────────────────────┐  ║
║  │                               │  ║
║  ↓                               ↓  ║
║  Storage Subnet    Key Vault Subnet ║
║  (172.16.2.0/24)   (172.16.3.0/24) ║
║  [Private EP]      [Private EP]     ║
║                                      ║
║  ↓                               ↓  ║
║  Database Subnet   OpenAI Subnet    ║
║  (172.16.4.0/24)   (172.16.5.0/24) ║
║  [Private EP]      [Private EP]     ║
║                                      ║
╚══════════════════════════════════════╝
```

### Network Topology

The infrastructure uses a hub-and-spoke model with dedicated subnets for each service tier:

1. **App Subnet (172.16.1.0/24)**: Function App with VNet integration
   - Service Endpoints: Microsoft.Web, Microsoft.KeyVault
   - Delegation: Microsoft.Web/serverFarms
   - Purpose: Application tier with outbound private connectivity

2. **Storage Subnet (172.16.2.0/24)**: Storage Account private endpoint
   - Service Endpoints: Microsoft.Storage
   - Purpose: Function App backend storage isolation

3. **Key Vault Subnet (172.16.3.0/24)**: Key Vault private endpoint
   - Service Endpoints: Microsoft.KeyVault
   - Purpose: Secret management tier

4. **Database Subnet (172.16.4.0/24)**: SQL Database private endpoint
   - Service Endpoints: Microsoft.Sql
   - Purpose: Data persistence tier

5. **OpenAI Subnet (172.16.5.0/24)**: Azure OpenAI private endpoint
   - Purpose: AI/ML services tier

6. **Deployment Subnet (172.16.6.0/24)**: Cloud Shell container (optional)
   - Delegation: Microsoft.ContainerInstance/containerGroups
   - Purpose: Secure deployment access to private resources

### Security Layers

```
Layer 1: Network Isolation
  └─ VNet with private address space
  └─ Subnet segmentation per service
  └─ Private endpoints for all backend services

Layer 2: Access Control
  └─ Managed Identity for service-to-service auth
  └─ Network ACLs (deny by default)
  └─ Key Vault access policies (least privilege)

Layer 3: Secret Management
  └─ All credentials in Key Vault
  └─ No secrets in code or configuration
  └─ Automatic secret rotation support

Layer 4: Encryption
  └─ TLS 1.2 minimum for SQL
  └─ HTTPS for all web traffic
  └─ Private backbone for inter-service communication
```

## Components and Interfaces

### 1. Static Web App

**Purpose**: Public-facing frontend for user registration and game interface

**Configuration**:
- SKU: Standard (supports custom domains and linked backends)
- Location: Configurable via variable
- Backend Integration: Linked to Function App

**Interfaces**:
- Input: User HTTP requests (HTTPS)
- Output: Calls to Function App backend API

**Security**:
- Built-in HTTPS/TLS
- Optional Azure AD authentication
- Global CDN distribution

### 2. Function App

**Purpose**: Backend API for business logic, database operations, AI integration

**Configuration**:
- Runtime: Linux
- Plan: Consumption (Y1) for basic, Premium (EP1) for VNet integration
- Storage: Private endpoint enabled
- Identity: User-assigned managed identity
- VNet: Integrated with route-all-traffic enabled

**Interfaces**:
- Input: HTTP requests from Static Web App
- Output: 
  - Key Vault (via Managed Identity)
  - SQL Database (via private endpoint)
  - Azure OpenAI (via private endpoint)
  - Storage Account (via private endpoint)

**Key Settings**:
```hcl
app_settings = {
  "WEBSITE_RUN_FROM_PACKAGE" = "1"
  "KEY_VAULT_URI"            = "<key-vault-uri>"
  "SQL_CONNECTION_SECRET"    = "sql-connection-string"
  "OPENAI_ENDPOINT_SECRET"   = "openai-endpoint"
  "OPENAI_KEY_SECRET"        = "openai-key"
}
```

**Security**:
- Managed Identity for authentication
- VNet integration for private connectivity
- No storage account keys in configuration (uses Managed Identity)

### 3. Key Vault

**Purpose**: Secure storage for secrets, keys, and certificates

**Configuration**:
- SKU: Standard
- Purge Protection: Configurable (disabled for dev/test)
- Soft Delete: Enabled (90 days)
- Network ACLs: Deny by default
- Private Endpoint: Enabled

**Interfaces**:
- Input: Secret retrieval requests from Function App (Managed Identity)
- Output: Returns secrets (SQL credentials, OpenAI keys)

**Access Policies**:
```hcl
Function App Managed Identity:
  - Secrets: Get, List

Administrator:
  - Secrets: Get, List, Set, Delete, Purge, Recover
```

**Secrets Stored**:
- `sql-connection-string`: Full SQL connection string
- `sql-username`: SQL admin username
- `sql-server-fqdn`: SQL server FQDN (private endpoint)
- `sql-database-name`: Database name
- `openai-endpoint`: OpenAI endpoint URL (private endpoint)
- `openai-key`: OpenAI API key

### 4. SQL Database

**Purpose**: Primary data store for user information, game state, analytics

**Configuration**:
- Server Version: 12.0
- Database SKU: Basic (for dev), General Purpose (for production)
- Max Size: Configurable (2GB default)
- TLS: 1.2 minimum
- Public Access: Disabled
- Private Endpoint: Enabled

**Interfaces**:
- Input: SQL queries from Function App (via private endpoint)
- Output: Query results

**Security**:
- SQL authentication with strong random password
- Credentials stored in Key Vault
- Private endpoint only (no public access)
- VNet rules for additional protection

**Schema Design** (Example):
```sql
Users Table:
  - UserId (PK)
  - Username (Unique)
  - Email (Unique)
  - CreatedAt
  - LastLogin
  - IsActive

GameSessions Table:
  - SessionId (PK)
  - UserId (FK)
  - StartTime
  - EndTime
  - Score
  - Level

AIInteractions Table:
  - InteractionId (PK)
  - UserId (FK)
  - Prompt
  - Response
  - TokensUsed
  - Timestamp
```

### 5. Azure OpenAI

**Purpose**: AI-powered game features (NPC dialogue, story generation, personalization)

**Configuration**:
- SKU: S0 (Standard)
- Location: East US (OpenAI availability)
- Public Access: Configurable (disabled for production)
- Private Endpoint: Optional (enabled where supported)

**Interfaces**:
- Input: API requests from Function App (via private endpoint)
- Output: AI-generated content

**Model Deployments**:
```hcl
deployments = {
  "gpt-35-turbo" = {
    model_name    = "gpt-35-turbo"
    model_version = "0613"
    scale_type    = "Standard"
    capacity      = 10
  }
}
```

**Security**:
- API key stored in Key Vault
- Private endpoint for network isolation
- Custom subdomain for dedicated endpoint

### 6. Storage Account

**Purpose**: Function App backend storage (code, logs, data)

**Configuration**:
- Tier: Standard
- Replication: LRS (Locally Redundant)
- Public Access: Disabled
- Network: Deny by default
- Private Endpoint: Enabled

**Interfaces**:
- Input: Function App runtime operations
- Output: Blob storage for function code and data

**Security**:
- Private endpoint only
- Network ACLs allowing only Function App subnet
- Managed Identity for access (no keys in configuration)

### 7. Virtual Network

**Purpose**: Network isolation and private connectivity

**Configuration**:
- Address Space: 172.16.0.0/16 (avoids common 10.x conflicts)
- Subnets: 6 dedicated subnets (see Network Topology)

**Interfaces**:
- Provides private IP space for all services
- Routes traffic between subnets
- Hosts private endpoints

### 8. Private DNS Zones

**Purpose**: Name resolution for private endpoints within VNet

**Zones Created**:
- `privatelink.vaultcore.azure.net` (Key Vault)
- `privatelink.database.windows.net` (SQL Database)
- `privatelink.openai.azure.com` (Azure OpenAI)
- `privatelink.blob.core.windows.net` (Storage Account)

**Functionality**:
- Overrides public DNS within VNet
- Resolves service FQDNs to private IPs
- Linked to VNet for automatic resolution

## Data Models

### Terraform State Model

```hcl
State Structure:
  ├─ azurerm_resource_group
  ├─ azurerm_virtual_network
  ├─ azurerm_subnet (x6)
  ├─ random_string (for unique names)
  ├─ random_password (for SQL)
  ├─ module.function_app
  │  ├─ azurerm_storage_account
  │  ├─ azurerm_private_endpoint (storage)
  │  ├─ azurerm_service_plan
  │  ├─ azurerm_user_assigned_identity
  │  ├─ azurerm_linux_function_app
  │  └─ azurerm_app_service_virtual_network_swift_connection
  ├─ module.key_vault
  │  ├─ azurerm_key_vault
  │  ├─ azurerm_private_endpoint
  │  ├─ azurerm_private_dns_zone
  │  ├─ azurerm_private_dns_zone_virtual_network_link
  │  ├─ azurerm_private_dns_a_record
  │  └─ azurerm_key_vault_secret (x6)
  ├─ module.sql_database
  │  ├─ azurerm_mssql_server
  │  ├─ azurerm_mssql_database
  │  ├─ azurerm_private_endpoint
  │  ├─ azurerm_private_dns_zone
  │  ├─ azurerm_private_dns_zone_virtual_network_link
  │  └─ azurerm_private_dns_a_record
  ├─ module.openai
  │  ├─ azurerm_cognitive_account
  │  ├─ azurerm_cognitive_deployment (per model)
  │  ├─ azurerm_private_endpoint
  │  ├─ azurerm_private_dns_zone
  │  ├─ azurerm_private_dns_zone_virtual_network_link
  │  └─ azurerm_private_dns_a_record
  └─ module.static_web_app
     ├─ azurerm_static_web_app
     └─ azurerm_static_web_app_function_app_registration
```

### Variable Model

```hcl
Required Variables:
  - azurerm_resource_group_name: string
  - azurerm_resource_group_location: string

Network Variables:
  - vnet_address_space: list(string)
  - app_subnet_cidr: string
  - storage_subnet_cidr: string
  - keyvault_subnet_cidr: string
  - database_subnet_cidr: string
  - openai_subnet_cidr: string
  - deployment_subnet_cidr: string

Module-Specific Variables:
  - Defined in each module's variables.tf
  - Passed from main.tf to modules
```

### Output Model

```hcl
Outputs:
  - resource_group_name: string
  - resource_group_location: string
  - vnet_name: string
  - subnet_configuration: map(object)
  - static_web_app_url: string
  - key_vault_name: string
  - sql_server_name: string
  - openai_account_name: string
  - deployment_instructions: string
```

## Correctne
ss Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Configuration Analysis Properties

**Property 1: Private endpoint identification**
*For any* Terraform configuration, parsing the configuration files should correctly identify all resources that have private endpoint resources defined
**Validates: Requirements 1.1**

**Property 2: Public access identification**
*For any* Terraform configuration, parsing the configuration files should correctly identify all resources with public_network_access_enabled set to true
**Validates: Requirements 1.2**

**Property 3: VNet integration verification**
*For any* Function App configuration, if VNet integration is required, then the configuration should contain an azurerm_app_service_virtual_network_swift_connection resource with vnet_route_all_enabled set to true
**Validates: Requirements 1.3**

**Property 4: Managed Identity authentication**
*For any* Key Vault configuration with Function App access, the access policies should reference the Function App's managed identity object_id
**Validates: Requirements 1.4**

**Property 5: SQL credentials in Key Vault**
*For any* SQL Database configuration, there should exist corresponding Key Vault secret resources for the SQL connection string, username, and server FQDN
**Validates: Requirements 1.5**

### Deployment Configuration Properties

**Property 6: Key Vault private endpoint enforcement**
*For any* Key Vault resource in production configuration, the resource should have enable_private_endpoint set to true and public_network_access_enabled set to false (or network_acls default_action set to Deny)
**Validates: Requirements 2.1**

**Property 7: SQL Database private endpoint enforcement**
*For any* SQL Database server resource in production configuration, the resource should have enable_private_endpoint set to true and public_network_access_enabled set to false
**Validates: Requirements 2.2**

**Property 8: Storage Account private endpoint and ACLs**
*For any* Storage Account used by Function App, the resource should have enable_storage_private_endpoint set to true and network_rules with default_action set to Deny
**Validates: Requirements 2.4**

**Property 9: Function App VNet integration**
*For any* Function App requiring private connectivity, the configuration should include VNet integration with vnet_route_all_enabled set to true
**Validates: Requirements 3.1**

**Property 10: Function App managed identity for Key Vault**
*For any* Function App that accesses Key Vault, the Function App should have a managed identity configured and the Key Vault should have an access policy granting that identity Get and List permissions
**Validates: Requirements 3.2**

**Property 11: Private endpoint connectivity**
*For any* service with a private endpoint, the Function App should be able to connect to that service through the private endpoint (private IP) rather than public endpoint
**Validates: Requirements 3.3, 3.4, 3.5**

### Secret Management Properties

**Property 12: SQL password generation and storage**
*For any* SQL Database deployment, there should exist a random_password resource and a corresponding Key Vault secret resource storing that password
**Validates: Requirements 4.1**

**Property 13: OpenAI credentials in Key Vault**
*For any* Azure OpenAI deployment, there should exist Key Vault secret resources for both the API key and endpoint URL
**Validates: Requirements 4.2**

**Property 14: Function App secret retrieval**
*For any* Function App app_settings that reference secrets, the values should use Key Vault reference syntax or the Function App should have managed identity access to Key Vault
**Validates: Requirements 4.3**

**Property 15: Key Vault secret naming convention**
*For any* Key Vault secret, the name should follow kebab-case convention and be descriptive of its purpose (e.g., "sql-connection-string", "openai-key")
**Validates: Requirements 4.4**

**Property 16: Key Vault network ACLs**
*For any* Key Vault resource, the network_acls should have default_action set to Deny and virtual_network_subnet_ids should only include authorized subnets
**Validates: Requirements 4.5**

### Reusability Properties

**Property 17: No hardcoded subscription values**
*For any* Terraform configuration file, there should be no hardcoded subscription IDs, tenant IDs, or other subscription-specific values outside of variable declarations
**Validates: Requirements 5.1**

**Property 18: Random suffixes for unique names**
*For any* resource requiring a globally unique name (Storage Account, Key Vault, etc.), the name should incorporate a random_string resource to ensure uniqueness
**Validates: Requirements 5.2**

**Property 19: Consistent resource tagging**
*For any* Azure resource in the configuration, the resource should have a tags attribute that includes at minimum: project_owner, author, and environment
**Validates: Requirements 5.4**

**Property 20: Required outputs defined**
*For any* Terraform configuration, the outputs should include at minimum: resource_group_name, key_vault_name, sql_server_name, and connection URLs for all public-facing services
**Validates: Requirements 5.5**

### Network Architecture Properties

**Property 21: Subnet per service tier**
*For any* VNet configuration, there should be separate subnets defined for: app tier, storage tier, key vault tier, database tier, and AI tier (minimum 5 subnets)
**Validates: Requirements 6.1**

**Property 22: Service endpoints on subnets**
*For any* subnet that hosts services requiring service endpoints, the subnet should have the appropriate service_endpoints configured (e.g., Microsoft.Web for app subnet, Microsoft.Storage for storage subnet)
**Validates: Requirements 6.2**

**Property 23: Subnet delegations**
*For any* subnet that requires delegation (e.g., Function App subnet), the subnet should have the appropriate delegation block configured (e.g., Microsoft.Web/serverFarms)
**Validates: Requirements 6.3**

**Property 24: Private endpoint subnet isolation**
*For any* set of private endpoints, each private endpoint should reference a different subnet_id to ensure isolation
**Validates: Requirements 6.4**

**Property 25: Private DNS zone VNet links**
*For any* Private DNS zone created, there should exist a corresponding azurerm_private_dns_zone_virtual_network_link resource linking it to the VNet
**Validates: Requirements 6.5**

### Module Design Properties

**Property 26: Module variable documentation**
*For any* Terraform module, all variables in variables.tf should have a description attribute and appropriate variables should have default values
**Validates: Requirements 7.1**

**Property 27: Module outputs defined**
*For any* Terraform module, the outputs.tf file should define outputs for all values that other modules or applications need to reference
**Validates: Requirements 7.2**

**Property 28: Optional feature flags**
*For any* Terraform module with optional features, there should be boolean variables (e.g., enable_private_endpoint, create_managed_identity) controlling those features
**Validates: Requirements 7.3**

**Property 29: Private endpoint as optional**
*For any* module that supports private endpoints, the private endpoint resources should use count based on an enable_private_endpoint variable
**Validates: Requirements 7.4**

**Property 30: Module naming and tagging consistency**
*For any* Terraform module, all resource names should follow a consistent pattern (e.g., "${var.name}-suffix") and all resources should accept and apply a tags variable
**Validates: Requirements 7.5**

### Access Control Properties

**Property 31: Function App least privilege Key Vault access**
*For any* Key Vault access policy for a Function App managed identity, the secret_permissions should be limited to ["Get", "List"] only
**Validates: Requirements 8.1**

**Property 32: Administrator full Key Vault access**
*For any* Key Vault access policy for an administrator, the secret_permissions should include ["Get", "List", "Set", "Delete", "Purge", "Recover"]
**Validates: Requirements 8.2**

**Property 33: SQL authentication via Key Vault**
*For any* SQL Database server, the administrator_login and administrator_login_password should be defined, and the password should be stored in a Key Vault secret
**Validates: Requirements 8.3**

**Property 34: Managed identity assignment**
*For any* managed identity resource, it should only be assigned to resources that require it (Function App for Key Vault access)
**Validates: Requirements 8.4**

**Property 35: Network ACL deny by default**
*For any* resource with network_acls or network_rules, the default_action should be set to "Deny" and only specific subnet IDs should be in the allowed list
**Validates: Requirements 8.5**

### Deployment Validation Properties

**Property 36: Private endpoint provisioning state**
*For any* deployed private endpoint, querying the Azure resource should return a provisioningState of "Succeeded"
**Validates: Requirements 10.1**

**Property 37: Private DNS zone VNet link state**
*For any* deployed Private DNS zone VNet link, querying the Azure resource should return a provisioningState of "Succeeded" and registrationEnabled should match the configuration
**Validates: Requirements 10.2**

## Error Handling

### Terraform Errors

**1. Resource Already Exists**
- **Scenario**: Deploying to a subscription where resources with the same name already exist
- **Handling**: Use random_string suffixes for globally unique names
- **Recovery**: Import existing resources or destroy and recreate

**2. Insufficient Permissions**
- **Scenario**: Service principal lacks permissions to create resources
- **Handling**: Validate permissions before deployment
- **Recovery**: Grant required RBAC roles (Contributor, User Access Administrator)

**3. Resource Provider Not Registered**
- **Scenario**: Required resource providers not registered in subscription
- **Handling**: Document required providers in README
- **Recovery**: Register providers using Azure CLI or Portal

**4. Quota Exceeded**
- **Scenario**: Subscription quota limits reached (e.g., vCPU quota)
- **Handling**: Document quota requirements
- **Recovery**: Request quota increase or use lower SKUs

**5. Private Endpoint Creation Fails**
- **Scenario**: Private endpoint creation fails due to network configuration
- **Handling**: Validate subnet configuration and service availability
- **Recovery**: Check subnet has no NSG blocking traffic, verify service supports private endpoints

### Network Connectivity Errors

**1. DNS Resolution Fails**
- **Scenario**: Private endpoint FQDN resolves to public IP instead of private IP
- **Handling**: Verify Private DNS zone is linked to VNet
- **Recovery**: Check DNS zone link, verify A record exists, restart Function App

**2. Function App Cannot Access Key Vault**
- **Scenario**: Function App gets 403 Forbidden from Key Vault
- **Handling**: Verify managed identity is configured and access policy exists
- **Recovery**: Check identity principal ID, verify access policy, check network ACLs

**3. SQL Connection Timeout**
- **Scenario**: Function App cannot connect to SQL Database
- **Handling**: Verify private endpoint is created and DNS resolves correctly
- **Recovery**: Check private endpoint state, verify connection string, test DNS resolution

**4. Storage Account Access Denied**
- **Scenario**: Function App cannot access storage account
- **Handling**: Verify private endpoint and network ACLs
- **Recovery**: Check network rules allow Function App subnet, verify private endpoint

### Secret Management Errors

**1. Secret Not Found**
- **Scenario**: Function App tries to retrieve non-existent secret
- **Handling**: Verify secret name matches Key Vault secret
- **Recovery**: Check secret exists in Key Vault, verify app settings reference correct name

**2. Secret Access Denied**
- **Scenario**: Managed identity lacks permission to read secret
- **Handling**: Verify access policy grants Get and List permissions
- **Recovery**: Update access policy, verify identity object ID

**3. Secret Value Invalid**
- **Scenario**: Retrieved secret value is malformed or incorrect
- **Handling**: Validate secret format during deployment
- **Recovery**: Update secret value in Key Vault, restart Function App

### Deployment Errors

**1. Module Dependency Failure**
- **Scenario**: Module fails because dependent resource not ready
- **Handling**: Use explicit depends_on in Terraform
- **Recovery**: Apply in stages, verify dependencies

**2. Terraform State Lock**
- **Scenario**: State file locked by another operation
- **Handling**: Use remote state with locking (Azure Storage)
- **Recovery**: Wait for lock release or force unlock if safe

**3. Plan/Apply Mismatch**
- **Scenario**: Resources changed between plan and apply
- **Handling**: Use -out flag to save plan
- **Recovery**: Re-run plan and review changes

## Testing Strategy

### Unit Testing

Unit tests verify specific Terraform configurations and module behaviors:

**1. Module Variable Validation**
- Test that required variables are defined
- Test that default values are appropriate
- Test that variable types are correct

**2. Resource Configuration**
- Test that resources have required attributes
- Test that conditional resources use count correctly
- Test that resource names follow conventions

**3. Output Validation**
- Test that required outputs are defined
- Test that output values reference correct resources
- Test that sensitive outputs are marked as sensitive

**Example Unit Test (using Terratest)**:
```go
func TestKeyVaultModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/key-vault",
        Vars: map[string]interface{}{
            "key_vault_name": "test-kv-123",
            "location": "eastus",
            "resource_group_name": "test-rg",
            "tenant_id": "test-tenant-id",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndPlan(t, terraformOptions)
    
    // Verify plan contains private endpoint
    planStruct := terraform.InitAndPlanAndShow(t, terraformOptions)
    assert.Contains(t, planStruct, "azurerm_private_endpoint")
}
```

### Property-Based Testing

Property-based tests verify universal properties across many configurations:

**Testing Framework**: We'll use Terratest (Go) for property-based testing of Terraform configurations.

**Test Configuration**: Each property test should run with at least 100 iterations to ensure coverage across different input combinations.

**Property Test Tagging**: Each property-based test must include a comment with the format:
`// Feature: azure-infra-security-enhancement, Property X: <property description>`

**1. Configuration Parsing Properties**
- Generate random Terraform configurations
- Verify property identification works correctly
- Test with various resource combinations

**2. Deployment Validation Properties**
- Deploy infrastructure with random valid configurations
- Verify all properties hold after deployment
- Test with different SKUs and options

**3. Network Configuration Properties**
- Generate random subnet configurations
- Verify service endpoints are correctly assigned
- Test with different address spaces

**Example Property Test**:
```go
// Feature: azure-infra-security-enhancement, Property 16: Key Vault network ACLs
func TestProperty_KeyVaultNetworkACLs(t *testing.T) {
    for i := 0; i < 100; i++ {
        // Generate random configuration
        kvName := fmt.Sprintf("test-kv-%d", rand.Intn(10000))
        
        terraformOptions := &terraform.Options{
            TerraformDir: "../modules/key-vault",
            Vars: map[string]interface{}{
                "key_vault_name": kvName,
                "network_acls_default_action": "Deny",
                "allowed_subnet_ids": generateRandomSubnetIds(),
            },
        }
        
        defer terraform.Destroy(t, terraformOptions)
        terraform.InitAndApply(t, terraformOptions)
        
        // Verify property: network ACLs should deny by default
        kvResource := azure.GetKeyVault(t, kvName, "test-rg", "")
        assert.Equal(t, "Deny", kvResource.NetworkAcls.DefaultAction)
        assert.NotEmpty(t, kvResource.NetworkAcls.VirtualNetworkSubnetIds)
    }
}
```

### Integration Testing

Integration tests verify end-to-end functionality:

**1. Full Infrastructure Deployment**
- Deploy complete infrastructure
- Verify all resources are created
- Verify all connections work

**2. Function App Connectivity**
- Deploy Function App with test code
- Test Key Vault secret retrieval
- Test SQL Database connection
- Test Azure OpenAI API calls

**3. Private Endpoint Validation**
- Verify DNS resolution returns private IPs
- Test connectivity through private endpoints
- Verify public access is blocked

**Example Integration Test**:
```go
func TestFullInfrastructureDeployment(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../",
        VarFiles: []string{"test.tfvars"},
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    // Get outputs
    kvName := terraform.Output(t, terraformOptions, "key_vault_name")
    sqlServer := terraform.Output(t, terraformOptions, "sql_server_name")
    
    // Verify Key Vault is accessible
    secrets := azure.ListKeyVaultSecrets(t, kvName)
    assert.Contains(t, secrets, "sql-connection-string")
    
    // Verify SQL Database is accessible via private endpoint
    // (This would require running from within the VNet)
}
```

### Manual Testing

Manual tests for aspects that cannot be automated:

**1. Documentation Review**
- Verify architecture diagrams are accurate
- Verify troubleshooting guides are helpful
- Verify cost optimization strategies are documented

**2. User Experience**
- Deploy to a new subscription
- Follow deployment instructions
- Verify clarity of error messages

**3. Security Review**
- Review network configuration
- Verify least privilege access
- Check for exposed secrets

### Test Execution Strategy

**1. Pre-Commit Tests**
- Terraform fmt and validate
- Variable validation
- Module structure checks

**2. Pull Request Tests**
- Unit tests for changed modules
- Property tests for affected properties
- Integration tests for full deployment

**3. Release Tests**
- Full integration test suite
- Multi-subscription deployment test
- Performance and cost validation

**4. Post-Deployment Tests**
- Connectivity validation
- Secret access validation
- DNS resolution validation

### Test Data Management

**1. Test Subscriptions**
- Use dedicated test subscriptions
- Clean up resources after tests
- Monitor costs

**2. Test Credentials**
- Use service principals for automation
- Store credentials in CI/CD secrets
- Rotate regularly

**3. Test State**
- Use separate state files for tests
- Clean up state after tests
- Use remote state for team testing
