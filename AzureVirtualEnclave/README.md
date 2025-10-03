# Azure Virtual Enclave Infrastructure

This Bicep solution deploys a scalable Azure Virtual Enclave infrastructure with the following architecture:

## Architecture Overview

```
Subscription
└── Resource Group
    ├── Community 1
    │   ├── Virtual Network (10.0.0.0/16)
    │   ├── Network Security Group
    │   ├── Enclave 1
    │   │   ├── Subnet (10.0.0.0/24)
    │   │   ├── Availability Set
    │   │   ├── Key Vault
    │   │   ├── Workload 1 (VM + Confidential Computing)
    │   │   ├── Workload 2 (VM + Confidential Computing)
    │   │   └── ...
    │   ├── Enclave 2
    │   │   ├── Subnet (10.0.1.0/24)
    │   │   └── ...
    │   └── ...
    ├── Community 2
    │   ├── Virtual Network (10.1.0.0/16)
    │   └── ...
    └── ...
```

## Features

- **Scalable Architecture**: Deploy N communities, M enclaves per community, O workloads per enclave
  - Optional compact naming mode (`useCompactNames=true`) to avoid 30-character enclave name limit in preview
- **Confidential Computing**: Uses DCsv3 series VMs with hardware-based trusted execution environments
- **Network Isolation**: Each community has its own virtual network with isolated subnets per enclave
- **Security**:
  - **Azure Virtual Enclave (AVE)**: Native secure connectivity and access management
  - Disk encryption with customer-managed keys
  - Key Vault for secret management
  - Network security groups with least privilege access
  - Managed identities for secure resource access
- **High Availability**: Availability sets for workload distribution
- **Attestation**: Built-in attestation services for confidential computing verification

## Documentation

- **[Quick Start Guide](QUICK-START.md)**: **START HERE** - Simple development deployments with minimal and basic configurations
- **[Nested Configuration Guide](NESTED-CONFIG-GUIDE.md)**: Complete guide to individual enclave and workload configurations
- **[Parameters Documentation](PARAMETERS.md)**: Comprehensive guide to all deployment parameters, including approval settings, network configuration, and governance options  
- **[Network Planning Guide](NETWORK-PLANNING.md)**: Address space planning and network configuration examples
- **[Deployment Guide](#deployment)**: Step-by-step deployment instructions
- **[Architecture Details](#architecture-overview)**: Technical architecture and design decisions

## Files Structure

```
AzureVirtualEnclave/
├── solution.bicep                    # Main deployment template
├── solution.bicepparam              # Simple development parameters  
├── solution.minimal.bicepparam      # Minimal setup parameters
├── QUICK-START.md                   # Quick deployment guide
├── NESTED-CONFIG-GUIDE.md          # Advanced configuration guide
├── PARAMETERS.md                    # Comprehensive parameter documentation
├── NETWORK-PLANNING.md             # Network configuration examples
├── deploy.ps1                      # PowerShell deployment script
├── README.md                  # This file
└── modules/
    ├── community.bicep        # Community-level resources
    ├── enclave.bicep          # Enclave-level resources
    └── workload.bicep         # Individual workload resources
```

## Prerequisites

- Azure CLI installed and configured
- Bicep CLI installed (or use `az bicep install`)
- Azure subscription with appropriate permissions
- PowerShell 5.1 or later (for deployment script)

## Quick Start

### Option 1: Using PowerShell Script (Recommended)

```powershell
# Basic deployment with default parameters
.\deploy.ps1

# Custom deployment
.\deploy.ps1 -BaseName "myenclave" -Location "West US 2" -NumberOfCommunities 3 -NumberOfEnclavesPerCommunity 2 -NumberOfWorkloadsPerEnclave 4

# What-if deployment (preview changes)
.\deploy.ps1 -WhatIf
```

### Option 2: Using Azure CLI directly

```bash
# Set environment variable for admin password
export ADMIN_PASSWORD="YourSecurePassword123!"

# Deploy using bicep parameters file
az deployment sub create \
  --name "ave-deployment" \
  --location "East US 2" \
  --template-file solution.bicep \
  --parameters solution.bicepparam
```

### Option 3: Using custom parameters

```bash
az deployment sub create \
  --name "ave-deployment" \
  --location "East US 2" \
  --template-file solution.bicep \
  --parameters baseName="myenclave" \
               numberOfCommunities=2 \
               numberOfEnclavesPerCommunity=3 \
               numberOfWorkloadsPerEnclave=2 \
               adminPassword="YourSecurePassword123!"
```

## Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `baseName` | string | - | Base name prefix for all resources |
| `location` | string | deployment location | Azure region for deployment |
| `numberOfCommunities` | int | 2 | Number of communities to deploy (1-10) |
| `numberOfEnclavesPerCommunity` | int | 2 | Number of enclaves per community (1-5) |
| `numberOfWorkloadsPerEnclave` | int | 3 | Number of workloads per enclave (1-10) |
| `adminPassword` | securestring | - | Admin password for VMs |
| `enclaveConfig` | object | see params | VM size, networking, and other config |
| `tags` | object | see params | Resource tags |

## Enclave Configuration

The `enclaveConfig` object supports the following properties:

```json
{
  "vmSize": "Standard_DC2s_v3",        // Confidential Computing VM size
  "adminUsername": "azureuser",         // VM admin username
  "virtualNetworkAddressPrefix": "10.0.0.0/16",  // Base network CIDR
  "subnetAddressPrefix": "10.0.0.0/24"  // Base subnet CIDR
}
```

### Supported VM Sizes for Confidential Computing

- `Standard_DC2s_v3` - 2 vCPUs, 8 GB RAM
- `Standard_DC4s_v3` - 4 vCPUs, 16 GB RAM  
- `Standard_DC8s_v3` - 8 vCPUs, 32 GB RAM
- `Standard_DC16s_v3` - 16 vCPUs, 64 GB RAM
- `Standard_DC32s_v3` - 32 vCPUs, 128 GB RAM

## Network Architecture

Each community receives its own `/16` address space:
- Community 0: `10.0.0.0/16`
- Community 1: `10.1.0.0/16`
- Community N: `10.N.0.0/16`

Within each community, enclaves get `/24` subnets:
- Enclave 0: `10.N.0.0/24`
- Enclave 1: `10.N.1.0/24`
- Enclave M: `10.N.M.0/24`

Workloads receive static IPs starting from `.10`:
- Workload 0: `10.N.M.10`
- Workload 1: `10.N.M.11`
- Workload O: `10.N.M.(10+O)`

## Security Considerations

1. **Change Default Passwords**: Always use strong, unique passwords
2. **Network Security**: Review NSG rules for your security requirements
3. **Public IPs**: Consider removing public IPs for production deployments
4. **Key Management**: Implement proper key rotation policies
5. **Access Control**: Use Azure RBAC and conditional access policies
6. **Monitoring**: Enable Azure Security Center and Log Analytics

## Deployment Examples

### Small Development Environment
```powershell
.\deploy.ps1 -BaseName "dev-ave" -NumberOfCommunities 1 -NumberOfEnclavesPerCommunity 1 -NumberOfWorkloadsPerEnclave 2
```
*Deploys: 1 community, 1 enclave, 2 workloads = 2 VMs*

### Medium Testing Environment  
```powershell
.\deploy.ps1 -BaseName "test-ave" -NumberOfCommunities 2 -NumberOfEnclavesPerCommunity 2 -NumberOfWorkloadsPerEnclave 3
```
*Deploys: 2 communities, 4 enclaves, 12 workloads = 12 VMs*

### Large Production Environment
```powershell
.\deploy.ps1 -BaseName "prod-ave" -NumberOfCommunities 5 -NumberOfEnclavesPerCommunity 3 -NumberOfWorkloadsPerEnclave 4
```
*Deploys: 5 communities, 15 enclaves, 60 workloads = 60 VMs*

## Accessing Virtual Machines

### Azure Virtual Enclave (AVE) Native Access

Azure Virtual Enclave provides built-in secure connectivity and access management:

1. **AVE Portal Integration** → Access through Azure Virtual Enclave service console
2. **Native Security Controls** → Built-in identity and access management
3. **Encrypted Connectivity** → Hardware-backed secure channels to workloads
4. **Audit and Compliance** → Comprehensive logging and monitoring
5. **Zero Trust Access** → Identity-based access without exposing public endpoints

### AVE Security Features

- **Hardware-based Attestation**: Cryptographic proof of enclave integrity
- **Secure Communication**: End-to-end encrypted channels
- **Identity Integration**: Azure AD/Entra ID integration
- **Policy Enforcement**: Fine-grained access controls
- **Audit Logging**: Complete session and access audit trails

### Direct VM Access (Not Recommended)

⚠️ **Important**: AVE workloads do not use public IP addresses. All connectivity should be through AVE's secure channels.

For troubleshooting scenarios only:
- Access must be configured through AVE service console
- Direct networking access violates AVE security model
- Use AVE's native secure access for all scenarios

## Monitoring and Management

After deployment, you can monitor your infrastructure using:

- **Azure Portal**: Resource groups, VMs, networking
- **Azure Monitor**: Performance metrics and logs
- **Key Vault**: Secret and key management
- **Security Center**: Security recommendations and compliance
- **Bastion Logs**: Connection audit trails and session monitoring

## Cost Optimization

- Use appropriate VM sizes for your workload requirements
- Consider reserved instances for production deployments  
- Implement auto-shutdown policies for development environments
- Monitor and optimize storage usage
- Use Azure Cost Management for ongoing cost analysis

## Troubleshooting

### Common Issues

1. **Deployment Fails**: Check subscription quotas for DCsv3 VMs
2. **Network Connectivity**: Verify NSG rules and routing
3. **Key Vault Access**: Ensure proper RBAC permissions
4. **VM Boot Issues**: Check boot diagnostics in Azure Portal

### Preview Known Issues (US Gov Azure Virtual Enclave)
| Issue | Description | Mitigation |
|-------|-------------|------------|
| approvalSettings BadRequest | Any non-null approvalSettings payload returns BadRequest | Omit approvalSettings (template omits by default) |
| Enclave name length >30 | Verbose name pattern can exceed limit | Enable compact naming (`useCompactNames=true`) or shorten `baseName` |
| Virtual Hub InternalServerError | Intermittent failure provisioning virtual hub | Retry minimal (community+one enclave); capture correlationId; check Activity Log |

### Naming Patterns
Verbose enclave name: `<baseName>-community-<communityIndex>-enclave-<enclaveIndex>`
Compact enclave name: `<baseName>c<communityIndex>e<enclaveIndex>`

### Useful Commands

```powershell
# Check deployment status
az deployment sub show --name "ave-deployment"

# List all resources in resource group  
az resource list --resource-group "ave-dev-rg"

# Connect to VM via RDP/SSH
az vm show --resource-group "ave-dev-rg" --name "ave-dev-community-0-enclave-0-workload-0-vm" --show-details
```

## Contributing

When making changes to this template:

1. Follow Azure Bicep best practices
2. Update the README with any new parameters or features
3. Test deployments in a development subscription
4. Ensure proper error handling and validation

## License

This project is provided as-is for educational and development purposes.