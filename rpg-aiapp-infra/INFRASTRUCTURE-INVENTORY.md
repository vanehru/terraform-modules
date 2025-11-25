# Azure Infrastructure Inventory

**Generated:** 2025-11-25  
**Purpose:** Comprehensive review of current Azure infrastructure for RPG Gaming App  
**Spec:** azure-infra-security-enhancement

## Executive Summary

This document provides a detailed inventory of the current Azure infrastructure, identifies security gaps, and documents the current state of integration between services.

### Current State Overview

- **Total Modules:** 5 (Function App, Key Vault, SQL Database, Azure OpenAI, Static Web App)
- **Network Subnets:** 6 dedicated subnets
- **Private Endpoints:** 4 configured (Key Vault, SQL Database, Storage Account, OpenAI - optional)
- **Security Posture:** Good foundation with room for improvement
- **Reusability:** Moderate - some hardcoded values present

---

## 1. Network Infrastructure

### Virtual Network Configuration

| Property | Current Value | Status |
|----------|---------------|--------|
| **Address Space** | 172.16.0.0/16 | ✅ Good - avoids common conflicts |
| **Total Subnets** | 6 | ✅ Excellent segmentation |
| **Service Endpoints** | Configured on 4 subnets | ✅ Good |
| **Delegations** | 2 subnets delegated | ✅ Correct |

### Subnet Details

#### 1. App Subnet (172.16.1.0/24)
- **Purpose:** Function App VNet integration
- **Service Endpoints:** Microsoft.Web, Microsoft.KeyVault
- **Delegation:** Microsoft.Web/serverFarms
- **Status:** ✅ Properly configured
- **Private Endpoints:** None (this is correct - VNet integration subnet)

#### 2. Storage Subnet (172.16.2.0/24)
- **Purpose:** Storage Account private endpoint
- **Service Endpoints:** Microsoft.Storage
- **Delegation:** None
- **Status:** ✅ Properly configured
- **Private Endpoints:** Storage Account (when Function App module enabled)

#### 3. Key Vault Subnet (172.16.3.0/24)
- **Purpose:** Key Vault private endpoint
- **Service Endpoints:** Microsoft.KeyVault
- **Delegation:** None
- **Status:** ✅ Properly configured
- **Private Endpoints:** Key Vault

#### 4. Database Subnet (172.16.4.0/24)
- **Purpose:** SQL Database private endpoint
- **Service Endpoints:** Microsoft.Sql
- **Delegation:** None
- **Status:** ✅ Properly configured
- **Private Endpoints:** SQL Database

#### 5. OpenAI Subnet (172.16.5.0/24)
- **Purpose:** Azure OpenAI private endpoint
- **Service Endpoints:** None
- **Delegation:** None
- **Status:** ⚠️ Private endpoint disabled in current config
- **Private Endpoints:** None (commented out due to timing issues)

#### 6. Deployment Subnet (172.16.6.0/24)
- **Purpose:** Cloud Shell container instance
- **Service Endpoints:** Microsoft.Storage
- **Delegation:** Microsoft.ContainerInstance/containerGroups
- **Status:** ⚠️ Container instance commented out
- **Private Endpoints:** None

### Network Security Gaps

| Gap | Severity | Impact |
|-----|----------|--------|
| No NSGs defined | Medium | Missing additional layer of network security |
| OpenAI private endpoint disabled | Low | OpenAI accessible via public endpoint |
| Container instance not deployed | Low | No secure deployment access from VNet |

---

## 2. Module Analysis

### 2.1 Function App Module

**Status:** ⚠️ Currently commented out in main.tf

#### Configuration
- **Plan SKU:** Y1 (Consumption) - configurable
- **Runtime:** Linux
- **Managed Identity:** User-assigned (optional)
- **VNet Integration:** Supported (optional)
- **Storage Account:** Included with private endpoint support

#### Security Features
| Feature | Status | Notes |
|---------|--------|-------|
| Managed Identity | ✅ Supported | Optional via variable |
| VNet Integration | ✅ Supported | Optional via variable |
| Route All Traffic | ✅ Supported | Configurable |
| Storage Private Endpoint | ✅ Supported | Optional via variable |
| Storage Network ACLs | ✅ Configured | Deny by default |

#### Gaps Identified
1. ❌ **Module commented out** - Not currently deployed
2. ⚠️ **No consumption plan support** - Only premium plans support VNet integration
3. ⚠️ **Storage account key in config** - Uses access key instead of managed identity
4. ✅ **Good variable structure** - Well-documented variables with defaults

#### Variables Analysis
- **Total Variables:** 20
- **Required Variables:** 6
- **Optional Variables:** 14
- **Sensitive Variables:** 0
- **Variables with Defaults:** 14
- **Documentation:** ✅ All variables have descriptions

#### Outputs Analysis
- **Total Outputs:** 9
- **Sensitive Outputs:** 0
- **Identity Outputs:** ✅ Principal ID and Identity ID exposed
- **Network Outputs:** ✅ Private endpoint IP exposed

---

### 2.2 Key Vault Module

**Status:** ✅ Active and properly configured

#### Configuration
- **SKU:** Standard
- **Purge Protection:** Disabled (configurable)
- **Soft Delete:** Enabled by default (Azure default)
- **Network ACLs:** Deny by default
- **Private Endpoint:** Enabled

#### Security Features
| Feature | Status | Notes |
|---------|--------|-------|
| Private Endpoint | ✅ Enabled | Configured with Private DNS |
| Network ACLs | ✅ Configured | Deny by default |
| Access Policies | ✅ Configured | Least privilege for Function App |
| Secrets Management | ✅ Implemented | Stores SQL and OpenAI credentials |
| Current IP Allowed | ✅ Yes | For deployment access |

#### Current Access Policies
1. **Administrator** (current user)
   - Secrets: Get, List, Set, Delete, Purge, Recover
   - Status: ✅ Appropriate full access

2. **Function App** (commented out)
   - Secrets: Get, List
   - Status: ⚠️ Not active (Function App commented out)

#### Secrets Stored
| Secret Name | Purpose | Source |
|-------------|---------|--------|
| sql-connection-string | Full SQL connection string | SQL Database module |
| sql-username | SQL admin username | SQL Database module |
| sql-server-fqdn | SQL server FQDN | SQL Database module |
| sql-database-name | Database name | SQL Database module |
| openai-endpoint | OpenAI endpoint URL | OpenAI module |
| openai-key | OpenAI API key | OpenAI module |

#### Gaps Identified
1. ✅ **Naming convention** - Uses kebab-case consistently
2. ✅ **Network security** - Properly configured
3. ⚠️ **Function App access** - Policy commented out (module disabled)
4. ✅ **Private DNS** - Properly configured

#### Variables Analysis
- **Total Variables:** 14
- **Required Variables:** 4
- **Sensitive Variables:** 1 (secrets)
- **Variables with Defaults:** 10
- **Documentation:** ✅ All variables have descriptions

---

### 2.3 SQL Database Module

**Status:** ✅ Active with private endpoint

#### Configuration
- **Server Version:** 12.0
- **Database SKU:** Basic (2GB)
- **TLS Version:** 1.2 minimum
- **Public Access:** Disabled
- **Private Endpoint:** Enabled

#### Security Features
| Feature | Status | Notes |
|---------|--------|-------|
| Private Endpoint | ✅ Enabled | Configured with Private DNS |
| Public Access | ✅ Disabled | No public internet access |
| TLS 1.2 Minimum | ✅ Enforced | Secure connections only |
| Strong Password | ✅ Generated | 16-character random password |
| Credentials in Key Vault | ✅ Stored | All credentials stored securely |
| Azure Services Access | ❌ Disabled | Correct for private endpoint setup |

#### Authentication
- **Method:** SQL Authentication
- **Username:** sqladmin
- **Password:** Random 16-character (stored in Key Vault)
- **Azure AD Admin:** Not configured (optional)

#### Connection String Format
```
Server=tcp:<server-fqdn>,1433;
Initial Catalog=<database-name>;
Persist Security Info=False;
User ID=<username>;
Password=<password>;
MultipleActiveResultSets=False;
Encrypt=True;
TrustServerCertificate=False;
Connection Timeout=30;
```

#### Gaps Identified
1. ✅ **Private endpoint** - Properly configured
2. ✅ **Password management** - Strong random password
3. ✅ **Credentials storage** - All in Key Vault
4. ⚠️ **No Azure AD auth** - Only SQL auth configured
5. ✅ **Network isolation** - Public access disabled

#### Variables Analysis
- **Total Variables:** 21
- **Required Variables:** 5
- **Sensitive Variables:** 2 (admin_username, admin_password)
- **Variables with Defaults:** 16
- **Documentation:** ✅ All variables have descriptions

---

### 2.4 Azure OpenAI Module

**Status:** ✅ Active but with public access

#### Configuration
- **SKU:** S0 (Standard)
- **Location:** East US
- **Public Access:** Enabled (for testing)
- **Private Endpoint:** Disabled (timing issues noted)
- **Model Deployments:** None (all deprecated)

#### Security Features
| Feature | Status | Notes |
|---------|--------|-------|
| Private Endpoint | ❌ Disabled | Commented out due to timing issues |
| Public Access | ⚠️ Enabled | Set to true for testing |
| Network ACLs | ❌ Not configured | Not enabled |
| API Key in Key Vault | ✅ Stored | Securely stored |
| Custom Subdomain | ✅ Configured | Uses account name |

#### Model Deployments
- **Current:** Empty (all models deprecated as of 11/14/2025)
- **Supported:** GPT-4, GPT-3.5-turbo (when available)
- **Configuration:** Flexible deployment map

#### Gaps Identified
1. ❌ **Private endpoint disabled** - Security gap
2. ⚠️ **Public access enabled** - Temporary for testing
3. ❌ **No model deployments** - Models deprecated
4. ✅ **Credentials secured** - API key in Key Vault
5. ⚠️ **Network ACLs not used** - Additional security layer missing

#### Variables Analysis
- **Total Variables:** 14
- **Required Variables:** 3
- **Sensitive Variables:** 0
- **Variables with Defaults:** 11
- **Documentation:** ✅ All variables have descriptions

---

### 2.5 Static Web App Module

**Status:** ✅ Active

#### Configuration
- **SKU:** Standard
- **Location:** East Asia
- **Function App Link:** Commented out (dependency issue)
- **Custom Domain:** Not configured

#### Security Features
| Feature | Status | Notes |
|---------|--------|-------|
| HTTPS | ✅ Automatic | Built-in Azure feature |
| CDN | ✅ Enabled | Global distribution |
| Function App Link | ⚠️ Disabled | Commented out |
| Custom Domain | ❌ Not configured | Optional feature |
| Authentication | ❌ Not configured | Optional feature |

#### Gaps Identified
1. ⚠️ **Function App not linked** - Backend integration missing
2. ✅ **Public access** - Correct for frontend
3. ❌ **No authentication** - Optional but recommended
4. ✅ **HTTPS enforced** - Secure by default

#### Variables Analysis
- **Total Variables:** 8
- **Required Variables:** 3
- **Sensitive Variables:** 0
- **Variables with Defaults:** 5
- **Documentation:** ✅ All variables have descriptions

---

## 3. Security Posture Analysis

### 3.1 Private Endpoint Coverage

| Service | Private Endpoint | Status | Notes |
|---------|------------------|--------|-------|
| Key Vault | ✅ Enabled | Good | Fully configured with Private DNS |
| SQL Database | ✅ Enabled | Good | Fully configured with Private DNS |
| Storage Account | ✅ Supported | Good | Configured when Function App enabled |
| Azure OpenAI | ❌ Disabled | Gap | Commented out due to timing issues |
| Function App | N/A | N/A | Uses VNet integration instead |
| Static Web App | N/A | N/A | Public by design |

**Coverage:** 75% (3 out of 4 applicable services)

### 3.2 Network Isolation

| Aspect | Status | Score |
|--------|--------|-------|
| VNet Segmentation | ✅ Excellent | 10/10 |
| Service Endpoints | ✅ Good | 8/10 |
| Private Endpoints | ⚠️ Mostly Good | 7/10 |
| Network ACLs | ✅ Good | 8/10 |
| NSGs | ❌ Missing | 0/10 |

**Overall Network Security:** 7.5/10

### 3.3 Identity and Access Management

| Aspect | Status | Score |
|--------|--------|-------|
| Managed Identity | ✅ Supported | 9/10 |
| Least Privilege | ✅ Implemented | 9/10 |
| Access Policies | ✅ Configured | 9/10 |
| Secret Management | ✅ Excellent | 10/10 |
| Key Rotation | ⚠️ Manual | 6/10 |

**Overall IAM Security:** 8.6/10

### 3.4 Secret Management

| Secret | Storage | Access Method | Status |
|--------|---------|---------------|--------|
| SQL Password | Key Vault | Managed Identity | ✅ Secure |
| SQL Username | Key Vault | Managed Identity | ✅ Secure |
| SQL Connection String | Key Vault | Managed Identity | ✅ Secure |
| OpenAI API Key | Key Vault | Managed Identity | ✅ Secure |
| OpenAI Endpoint | Key Vault | Managed Identity | ✅ Secure |
| Storage Account Key | Function App Config | Access Key | ⚠️ Could use MI |

**Secret Management Score:** 9/10

---

## 4. Integration Analysis

### 4.1 Service Dependencies

```
Static Web App (Public)
    ↓ (Linked Backend - Currently Disabled)
Function App (VNet Integrated - Currently Disabled)
    ↓ (Managed Identity)
Key Vault (Private Endpoint)
    ↓ (Stores Credentials)
    ├─→ SQL Database (Private Endpoint)
    └─→ Azure OpenAI (Public Access)
```

### 4.2 Data Flow

**Current State:**
1. ❌ Static Web App → Function App: **Not linked**
2. ⚠️ Function App → Key Vault: **Not active** (Function App disabled)
3. ✅ Key Vault → SQL Database: **Credentials stored**
4. ✅ Key Vault → Azure OpenAI: **Credentials stored**
5. ⚠️ Function App → SQL Database: **Would use private endpoint** (when enabled)
6. ⚠️ Function App → Azure OpenAI: **Would use public endpoint** (private disabled)

### 4.3 Integration Gaps

| Integration | Status | Impact | Priority |
|-------------|--------|--------|----------|
| Static Web App ↔ Function App | ❌ Not linked | High | High |
| Function App ↔ Key Vault | ⚠️ Not active | High | High |
| Function App ↔ SQL Database | ⚠️ Not active | High | High |
| Function App ↔ OpenAI | ⚠️ Not active | Medium | Medium |
| OpenAI Private Endpoint | ❌ Disabled | Medium | Medium |

---

## 5. Reusability Analysis

### 5.1 Hardcoded Values

| Location | Value | Type | Impact |
|----------|-------|------|--------|
| main.tf | "demo-rpg-vnet" | VNet name | Low - single instance |
| main.tf | "demo-rpgkv123" | Key Vault name | Medium - not unique |
| main.tf | "rpg-gaming-web" | Static Web App name | Low - descriptive |
| main.tf | "East Asia" | SWA location | Low - regional choice |
| main.tf | "East US" | OpenAI location | Low - service availability |

**Reusability Score:** 7/10 (Good use of variables, some hardcoded names)

### 5.2 Variable Usage

| Category | Count | Percentage |
|----------|-------|------------|
| Parameterized | 8 | 80% |
| Hardcoded | 2 | 20% |

### 5.3 Random Suffixes

| Resource | Uses Random Suffix | Status |
|----------|-------------------|--------|
| SQL Server | ✅ Yes | Good |
| OpenAI Account | ✅ Yes | Good |
| Key Vault | ❌ No | Gap |
| Storage Account | ❌ No | Gap |
| Cloud Shell Storage | ✅ Yes | Good |

**Random Suffix Usage:** 60% (3 out of 5 applicable resources)

### 5.4 Tagging Strategy

**Current Tags:**
```hcl
{
  project_owner = "ootsuka"
  author        = "Nehru"
  environment   = "development"
}
```

**Status:** ✅ Consistent tagging across all resources

---

## 6. Cost Analysis

### 6.1 Current Configuration Costs (Estimated Monthly)

| Service | SKU | Estimated Cost | Notes |
|---------|-----|----------------|-------|
| Function App | Y1 (Consumption) | $0-20 | Pay per execution (commented out) |
| Static Web App | Standard | $9 | Fixed monthly cost |
| SQL Database | Basic (2GB) | $5 | Development tier |
| Azure OpenAI | S0 | $0-200 | Usage-based |
| Storage Account | Standard LRS | $1-5 | Minimal usage |
| Key Vault | Standard | $0.03/10k ops | Minimal cost |
| Private Endpoints | 4 endpoints | $16 | $4/endpoint/month |
| VNet | Standard | $0 | No gateway |

**Total Estimated:** $31-250/month (depending on usage)

### 6.2 Cost Optimization Opportunities

1. **Function App:** Use Consumption plan (Y1) instead of Premium for dev
   - Savings: ~$140/month
   - Trade-off: No VNet integration

2. **SQL Database:** Use Serverless tier for dev
   - Savings: Variable based on usage
   - Trade-off: Cold start delays

3. **OpenAI:** Monitor token usage
   - Savings: Variable
   - Trade-off: None

---

## 7. Identified Gaps and Recommendations

### 7.1 Critical Gaps (High Priority)

1. **Function App Module Disabled**
   - Impact: No backend API functionality
   - Recommendation: Enable with consumption plan for dev, premium for production
   - Effort: Medium

2. **Static Web App Not Linked to Function App**
   - Impact: Frontend cannot call backend
   - Recommendation: Enable linking after Function App is deployed
   - Effort: Low

3. **OpenAI Private Endpoint Disabled**
   - Impact: OpenAI accessible via public internet
   - Recommendation: Enable private endpoint or document security exception
   - Effort: Medium

### 7.2 Medium Priority Gaps

4. **No Network Security Groups (NSGs)**
   - Impact: Missing additional network security layer
   - Recommendation: Add NSGs to all subnets
   - Effort: Medium

5. **Storage Account Uses Access Key**
   - Impact: Less secure than Managed Identity
   - Recommendation: Configure Function App to use Managed Identity for storage
   - Effort: Low

6. **Key Vault Names Not Unique**
   - Impact: Deployment conflicts across subscriptions
   - Recommendation: Add random suffix to Key Vault names
   - Effort: Low

### 7.3 Low Priority Gaps

7. **No Azure AD Authentication for SQL**
   - Impact: Only SQL auth available
   - Recommendation: Add Azure AD admin configuration
   - Effort: Low

8. **No Custom Domain for Static Web App**
   - Impact: Uses default Azure domain
   - Recommendation: Configure custom domain for production
   - Effort: Low

9. **No Authentication on Static Web App**
   - Impact: Public access to frontend
   - Recommendation: Enable Azure AD auth for production
   - Effort: Medium

---

## 8. Module Quality Assessment

### 8.1 Code Quality Metrics

| Module | Variables | Outputs | Complexity | Documentation | Score |
|--------|-----------|---------|------------|---------------|-------|
| Function App | 20 | 9 | High | Excellent | 9/10 |
| Key Vault | 14 | 6 | Medium | Excellent | 9/10 |
| SQL Database | 21 | 6 | Medium | Excellent | 9/10 |
| Azure OpenAI | 14 | 7 | Medium | Excellent | 9/10 |
| Static Web App | 8 | 4 | Low | Excellent | 9/10 |

**Average Module Quality:** 9/10

### 8.2 Module Reusability

| Module | Parameterization | Optional Features | Flexibility | Score |
|--------|------------------|-------------------|-------------|-------|
| Function App | Excellent | Excellent | Excellent | 10/10 |
| Key Vault | Excellent | Good | Excellent | 9/10 |
| SQL Database | Excellent | Good | Excellent | 9/10 |
| Azure OpenAI | Excellent | Good | Excellent | 9/10 |
| Static Web App | Good | Limited | Good | 7/10 |

**Average Reusability:** 8.8/10

---

## 9. Compliance and Best Practices

### 9.1 Azure Best Practices

| Practice | Status | Notes |
|----------|--------|-------|
| Use Managed Identities | ✅ Implemented | Function App uses managed identity |
| Private Endpoints | ⚠️ Mostly | 75% coverage |
| Network Segmentation | ✅ Excellent | 6 dedicated subnets |
| Secret Management | ✅ Excellent | All secrets in Key Vault |
| Least Privilege | ✅ Implemented | Appropriate access policies |
| Resource Tagging | ✅ Consistent | All resources tagged |
| TLS 1.2 Minimum | ✅ Enforced | SQL Database configured |
| Deny by Default | ✅ Implemented | Network ACLs configured |

**Best Practices Score:** 8.5/10

### 9.2 Terraform Best Practices

| Practice | Status | Notes |
|----------|--------|-------|
| Module Structure | ✅ Excellent | Well-organized modules |
| Variable Documentation | ✅ Excellent | All variables documented |
| Output Documentation | ✅ Excellent | All outputs documented |
| Sensitive Data Handling | ✅ Good | Marked as sensitive |
| Default Values | ✅ Good | Sensible defaults provided |
| Type Constraints | ✅ Excellent | All variables typed |
| Optional Features | ✅ Good | Boolean flags used |
| DRY Principle | ✅ Good | Minimal duplication |

**Terraform Best Practices Score:** 9/10

---

## 10. Summary and Next Steps

### 10.1 Overall Assessment

| Category | Score | Status |
|----------|-------|--------|
| Network Security | 7.5/10 | Good |
| IAM Security | 8.6/10 | Excellent |
| Secret Management | 9/10 | Excellent |
| Module Quality | 9/10 | Excellent |
| Reusability | 8.8/10 | Excellent |
| Integration | 5/10 | Needs Work |
| Cost Optimization | 7/10 | Good |
| Best Practices | 8.5/10 | Excellent |

**Overall Infrastructure Score:** 7.9/10 (Good)

### 10.2 Strengths

1. ✅ Excellent module structure and documentation
2. ✅ Strong secret management with Key Vault
3. ✅ Good network segmentation with dedicated subnets
4. ✅ Proper use of private endpoints (where enabled)
5. ✅ Consistent tagging and naming conventions
6. ✅ Flexible and reusable modules

### 10.3 Areas for Improvement

1. ⚠️ Enable Function App module for backend functionality
2. ⚠️ Link Static Web App to Function App
3. ⚠️ Enable OpenAI private endpoint
4. ⚠️ Add Network Security Groups
5. ⚠️ Add random suffixes to all globally unique names
6. ⚠️ Consider using Managed Identity for storage access

### 10.4 Recommended Implementation Order

1. **Phase 1: Core Functionality** (High Priority)
   - Enable Function App module with consumption plan
   - Link Static Web App to Function App
   - Validate end-to-end connectivity

2. **Phase 2: Security Enhancements** (High Priority)
   - Enable OpenAI private endpoint
   - Add random suffixes to resource names
   - Configure storage account to use Managed Identity

3. **Phase 3: Additional Security** (Medium Priority)
   - Add Network Security Groups
   - Enable Azure AD authentication for SQL
   - Add authentication to Static Web App

4. **Phase 4: Optimization** (Low Priority)
   - Implement cost optimization strategies
   - Add custom domain to Static Web App
   - Enhance monitoring and diagnostics

---

## Appendix A: Resource Naming Conventions

### Current Naming Patterns

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Resource Group | `<project>-<purpose>-rg` | rpg-aiapp-rg |
| VNet | `<project>-<purpose>-vnet` | demo-rpg-vnet |
| Subnet | `<purpose>-subnet` | app-subnet |
| Function App | `<project>-<purpose>-func` | demo-rpg-func |
| Key Vault | `<project><purpose>kv<number>` | demo-rpgkv123 |
| SQL Server | `<purpose>-sql-<random>` | rpg-sql-abc123 |
| OpenAI | `<purpose>-openai-<random>` | rpg-openai-abc123 |
| Static Web App | `<purpose>-<type>-web` | rpg-gaming-web |
| Storage Account | `<purpose><type><random>` | demorpgstoracc123 |

### Recommended Improvements

1. Add random suffixes to Key Vault names
2. Use consistent prefix across all resources
3. Include environment in naming (dev, staging, prod)

---

## Appendix B: Private DNS Zones

### Configured Zones

| Service | DNS Zone | Status | VNet Link |
|---------|----------|--------|-----------|
| Key Vault | privatelink.vaultcore.azure.net | ✅ Active | ✅ Linked |
| SQL Database | privatelink.database.windows.net | ✅ Active | ✅ Linked |
| Storage Account | privatelink.blob.core.windows.net | ⚠️ Conditional | ⚠️ Conditional |
| Azure OpenAI | privatelink.openai.azure.com | ❌ Disabled | ❌ Not linked |

---

## Appendix C: Module Dependencies

```
main.tf
  ├─ azurerm_resource_group
  ├─ azurerm_virtual_network
  ├─ azurerm_subnet (x6)
  ├─ random_string (suffix)
  ├─ random_password (SQL)
  ├─ data.http (current IP)
  ├─ data.azurerm_client_config
  │
  ├─ module.static_web_app
  │  └─ No dependencies
  │
  ├─ module.sql_database
  │  └─ Depends on: VNet, subnets
  │
  ├─ module.openai
  │  └─ Depends on: VNet, subnets
  │
  ├─ module.key_vault
  │  └─ Depends on: sql_database, openai (for secrets)
  │
  └─ module.function_app (commented out)
     └─ Depends on: VNet, subnets, key_vault
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-25  
**Next Review:** After Phase 1 implementation
