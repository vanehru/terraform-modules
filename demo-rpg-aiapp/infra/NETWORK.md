# Network Configuration Reference

## Overview

The infrastructure uses **172.16.0.0/16** address space to avoid conflicts with common on-premises networks that use 10.x.x.x ranges.

## Network Architecture

```
VNet: 172.16.0.0/16 (65,536 IPs)
├─ Subnet 1: App Subnet          172.16.1.0/24 (251 usable IPs)
├─ Subnet 2: Storage Subnet      172.16.2.0/24 (251 usable IPs)
├─ Subnet 3: Key Vault Subnet    172.16.3.0/24 (251 usable IPs)
├─ Subnet 4: Database Subnet     172.16.4.0/24 (251 usable IPs)
├─ Subnet 5: OpenAI Subnet       172.16.5.0/24 (251 usable IPs)
└─ Subnet 6: Deployment Subnet   172.16.6.0/24 (251 usable IPs)
```

## Subnet Details

| Subnet Name | CIDR | Purpose | Services |
|-------------|------|---------|----------|
| **app-subnet** | 172.16.1.0/24 | Application Tier | Function App (VNet Integration) |
| **storage-subnet** | 172.16.2.0/24 | Storage Tier | Storage Account Private Endpoint |
| **keyvault-subnet** | 172.16.3.0/24 | Security Tier | Key Vault Private Endpoint |
| **database-subnet** | 172.16.4.0/24 | Data Tier | SQL Database Private Endpoint |
| **openai-subnet** | 172.16.5.0/24 | AI Tier | Azure OpenAI Private Endpoint |
| **deployment-subnet** | 172.16.6.0/24 | Management Tier | Cloud Shell Container Instance |

## Why 172.16.0.0/16?

### Advantages

1. **Avoids 10.x.x.x conflicts**: Many corporate networks use 10.0.0.0/8
2. **VNet peering ready**: Can peer with other VNets without address overlap
3. **VPN/ExpressRoute compatible**: No conflicts when connecting to on-premises
4. **RFC 1918 compliant**: Standard private address space
5. **Room for growth**: Only using 6 out of 256 possible /24 subnets

### Use Cases

- ✅ Hybrid cloud deployments (Azure + on-premises)
- ✅ Multi-VNet architectures with peering
- ✅ Hub-and-spoke network topologies
- ✅ Organizations already using 10.x.x.x internally

## Customizing Network Ranges

### Option 1: Change VNet Range

Edit `terraform.tfvars`:

```hcl
# Use 10.x.x.x for standalone deployment
vnet_address_space = ["10.0.0.0/16"]
app_subnet_cidr    = "10.0.1.0/24"
# ... update all subnets
```

### Option 2: Hub-and-Spoke Architecture

```hcl
# This VNet is Spoke 1
vnet_address_space = ["10.10.0.0/16"]
app_subnet_cidr    = "10.10.1.0/24"
storage_subnet_cidr = "10.10.2.0/24"
# ... etc
```

### Option 3: Different Private Range

```hcl
# Use 192.168.x.x
vnet_address_space = ["192.168.0.0/16"]
app_subnet_cidr    = "192.168.1.0/24"
# ... etc
```

## IP Address Allocation

### Per Subnet Capacity

```
/24 subnet = 256 total IP addresses
  - 5 reserved by Azure
    • .0   = Network address
    • .1   = Gateway
    • .2   = DNS
    • .3   = DNS
    • .255 = Broadcast
  = 251 usable IP addresses
```

### VNet Capacity

```
/16 VNet = 65,536 total IP addresses
  - Current usage: 6 subnets × 256 IPs = 1,536 IPs
  - Available: 64,000 IPs for future subnets
  - Can support: 250 additional /24 subnets
```

## Network Security

### Private Endpoints

All backend services use private endpoints with IPs in their respective subnets:

```
Key Vault:       172.16.3.x (keyvault-subnet)
SQL Database:    172.16.4.x (database-subnet)
Azure OpenAI:    172.16.5.x (openai-subnet)
Storage Account: 172.16.2.x (storage-subnet)
```

### Service Endpoints

- **Microsoft.Web**: Enabled on app-subnet (172.16.1.0/24)
- **Microsoft.Storage**: Enabled on storage-subnet (172.16.2.0/24)
- **Microsoft.Sql**: Enabled on database-subnet (172.16.4.0/24)

## DNS Configuration

### Private DNS Zones

| Zone | Purpose | Example FQDN |
|------|---------|--------------|
| privatelink.vaultcore.azure.net | Key Vault | demo-rpgkv123.vault.azure.net → 172.16.3.x |
| privatelink.database.windows.net | SQL Database | rpg-gaming-sql-server.database.windows.net → 172.16.4.x |
| privatelink.openai.azure.com | Azure OpenAI | rpg-gaming-openai.openai.azure.com → 172.16.5.x |
| privatelink.blob.core.windows.net | Storage (Blob) | storage.blob.core.windows.net → 172.16.2.x |

## Deployment

### Verify Network Configuration

```bash
# View VNet details
terraform output vnet_address_space

# View all subnet details
terraform output subnet_configuration

# Test DNS resolution from Cloud Shell
nslookup demo-rpgkv123.vault.azure.net
# Should return 172.16.3.x
```

### Troubleshooting

```bash
# Check subnet allocations
az network vnet subnet list \
  --vnet-name demo-rpg-vnet \
  --resource-group rpg-aiapp-rg \
  --output table

# Verify private endpoint IPs
az network private-endpoint list \
  --resource-group rpg-aiapp-rg \
  --query '[].{Name:name, IP:customDnsConfigs[0].ipAddresses[0]}' \
  --output table
```

## Migration from 10.0.0.0/16

If you previously deployed with 10.0.0.0/16:

1. **Backup current state**: `terraform state pull > backup.tfstate`
2. **Destroy old resources**: `terraform destroy`
3. **Update variables**: Edit `terraform.tfvars` with new ranges
4. **Deploy new infrastructure**: `terraform apply`
5. **Verify connectivity**: Test private endpoint DNS resolution

**Note**: This is a destructive change requiring downtime.

## Best Practices

1. ✅ **Plan IP ranges in advance** - Document your addressing scheme
2. ✅ **Avoid overlaps** - Check on-premises and existing VNets
3. ✅ **Leave room for growth** - Don't use all subnets immediately
4. ✅ **Use consistent patterns** - Same subnet layout across environments
5. ✅ **Document changes** - Update this file when modifying network
6. ✅ **Test connectivity** - Verify private endpoint resolution after deployment

## Future Expansion

With 172.16.0.0/16, you can add:

- 172.16.7.0/24 → Additional app tier subnet
- 172.16.8.0/24 → Monitoring/logging subnet
- 172.16.9.0/24 → Integration services subnet
- 172.16.10.0/24 → Backup/DR subnet
- ... up to 172.16.255.0/24
