# Security Configuration Guide

## Overview

This infrastructure implements enterprise-grade security best practices for the RPG AI Application. All backend services are isolated using private endpoints and network security groups.

## Security Features Implemented

### 1. Network Security

#### Private Endpoints
- **Key Vault**: Private endpoint in dedicated subnet
- **SQL Database**: Private endpoint in dedicated subnet  
- **Azure OpenAI**: Private endpoint in dedicated subnet
- **Storage Account**: Private endpoint in dedicated subnet

#### Network Segmentation
- **6 Dedicated Subnets**: Each service tier has its own subnet
- **Network Security Groups**: Applied to application subnet with restrictive rules
- **Service Endpoints**: Configured for each service type
- **VNet Integration**: Function App integrated with VNet for outbound traffic

#### Network Access Control
```hcl
# Example NSG rule - HTTPS only
security_rule {
  name                       = "AllowHTTPS"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  destination_port_range     = "443"
}
```

### 2. Identity and Access Management

#### Managed Identities
- **Function App**: User-assigned managed identity
- **Container Instance**: System-assigned managed identity
- **No stored credentials**: All authentication via managed identities

#### Key Vault Access Policies
```hcl
access_policies = [
  {
    object_id          = function_app_identity
    secret_permissions = ["Get", "List"]  # Minimal permissions
  }
]
```

### 3. Data Protection

#### Encryption at Rest
- **Key Vault**: Hardware Security Module (HSM) backed
- **SQL Database**: Transparent Data Encryption (TDE) enabled
- **Storage Accounts**: Microsoft-managed encryption keys

#### Encryption in Transit
- **TLS 1.2 Minimum**: Enforced across all services
- **HTTPS Only**: All web traffic encrypted
- **Private DNS**: Internal name resolution

#### Data Retention
```hcl
blob_properties {
  versioning_enabled = true
  delete_retention_policy {
    days = 7
  }
}
```

### 4. Secret Management

#### Azure Key Vault Integration
- **Centralized Secrets**: All connection strings and API keys stored in Key Vault
- **Secret Rotation**: Automated secret rotation capabilities
- **Access Logging**: All secret access logged and monitored

#### Secrets Stored
- SQL connection strings
- Azure OpenAI API keys and endpoints
- Storage account connection strings
- Application-specific secrets

### 5. Database Security

#### SQL Server Configuration
```hcl
# Security settings
minimum_tls_version           = "1.2"
public_network_access_enabled = false
allow_azure_services          = true  # For managed services only
```

#### Access Control
- **Private Endpoint Only**: No public internet access
- **Strong Passwords**: 32-character generated passwords
- **Network Restrictions**: Access limited to VNet subnets

### 6. Function App Security

#### Runtime Security
```hcl
site_config {
  ftps_state              = "Disabled"
  http2_enabled           = true
  minimum_tls_version     = "1.2"
  scm_minimum_tls_version = "1.2"
  use_32_bit_worker       = false
}
```

#### Application Security
- **HTTPS Only**: All traffic encrypted
- **CORS Disabled**: No cross-origin requests allowed
- **VNet Integration**: All outbound traffic through VNet

### 7. Storage Security

#### Account Configuration
```hcl
# Security settings
min_tls_version                 = "TLS1_2"
allow_nested_items_to_be_public = false
https_traffic_only_enabled      = true
```

#### Access Control
- **Private Endpoints**: No public blob access
- **Network Rules**: Restricted to specific subnets
- **Shared Access Keys**: Managed through Key Vault

## Security Compliance

### Standards Alignment
- **Azure Security Benchmark**: Aligned with Microsoft recommendations
- **CIS Controls**: Implements critical security controls
- **Zero Trust**: Network microsegmentation and identity verification

### Monitoring and Logging
- **Azure Monitor**: Integrated logging for all resources
- **Key Vault Logging**: All secret access logged
- **Network Flow Logs**: VNet traffic monitoring

## Security Validation

### Automated Testing
The infrastructure includes comprehensive security tests:

```bash
# Run security validation tests
cd infra/test
go test -v -run TestSecurityConfiguration
```

### Manual Verification
1. **Network Isolation**: Verify no public endpoints accessible
2. **TLS Configuration**: Confirm TLS 1.2+ enforcement
3. **Access Policies**: Validate minimal permission principles
4. **Secret Access**: Test Key Vault integration

## Incident Response

### Security Monitoring
- **Failed Authentication**: Key Vault access failures
- **Network Anomalies**: Unusual traffic patterns
- **Configuration Changes**: Infrastructure modifications

### Response Procedures
1. **Immediate**: Isolate affected resources
2. **Investigation**: Review logs and access patterns
3. **Remediation**: Apply security patches/updates
4. **Documentation**: Update security configurations

## Best Practices

### Development
- **No Hardcoded Secrets**: Use Key Vault references
- **Least Privilege**: Minimal required permissions
- **Regular Updates**: Keep runtime versions current

### Operations
- **Secret Rotation**: Regular credential updates
- **Access Reviews**: Periodic permission audits
- **Security Scanning**: Automated vulnerability assessment

### Deployment
- **Infrastructure as Code**: Version-controlled security configs
- **Automated Testing**: Security validation in CI/CD
- **Change Management**: Documented security changes

## Security Contacts

For security issues or questions:
- **Infrastructure Team**: [Your Team Email]
- **Security Team**: [Security Team Email]
- **Emergency**: [Emergency Contact]

## References

- [Azure Security Documentation](https://docs.microsoft.com/en-us/azure/security/)
- [Azure Well-Architected Framework - Security](https://docs.microsoft.com/en-us/azure/architecture/framework/security/)
- [Azure Private Endpoint Documentation](https://docs.microsoft.com/en-us/azure/private-link/)