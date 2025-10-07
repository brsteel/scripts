# Azure Virtual Enclave Parameters Documentation

This document provides comprehensive documentation for all parameters used in the Azure Virtual Enclave Bicep deployment.

## Overview

Azure Virtual Enclave (AVE) uses the Microsoft.Mission resource provider to create secure, governed cloud environments. The template deploys a hierarchical structure:

```
Community (Governance Layer)
└── Virtual Enclave (Network Isolation)
    └── Workload (Container Objects)
```

## Parameter Reference

### Basic Parameters

#### `location`
- **Type**: `string`
- **Default**: `deployment().location`
- **Description**: Azure region where all resources will be deployed
- **Example**: `'East US'`, `'West Europe'`

#### `baseName`
- **Type**: `string`
- **Required**: Yes
- **Description**: Base name used as prefix for all resources
- **Example**: `'myave'` creates `myave-rg`, `myave-community-0`, etc.
- **Constraints**: Must follow Azure naming conventions

### Scale Parameters

#### `numberOfCommunities`
- **Type**: `int`
- **Default**: `2`
- **Range**: 1-10
- **Description**: Number of AVE communities to deploy
- **Note**: Communities provide top-level governance and approval workflows

#### `numberOfEnclavesPerCommunity`
- **Type**: `int`
- **Default**: `2`
- **Range**: 1-5
- **Description**: Number of virtual enclaves per community
- **Note**: Each enclave has its own isolated virtual network

#### `numberOfWorkloadsPerEnclave`
- **Type**: `int`
- **Default**: `3`
- **Range**: 1-10
- **Description**: Number of workloads per enclave
- **Note**: Workloads are container objects for deploying Azure resources

### Community Configuration (`communityConfigs`)

The `communityConfigs` array contains individual configuration objects for each community. **Important:** The array length must match the `numberOfCommunities` parameter, and each community must have unique network address spaces to prevent conflicts.

**Example for 3 Communities:**
```bicep
numberOfCommunities: 3
communityConfigs: [
  { addressSpace: '10.0.0.0/16', ... },  // Community 0
  { addressSpace: '10.1.0.0/16', ... },  // Community 1  
  { addressSpace: '10.2.0.0/16', ... }   // Community 2
]
```

#### Network Settings

##### `addressSpace`
- **Type**: `string`
- **Default**: `'10.0.0.0/16'`
- **Description**: CIDR address space for the community
- **Examples**: `'10.0.0.0/16'`, `'172.16.0.0/12'`, `'192.168.0.0/16'`

##### `dnsServers`
- **Type**: `array`
- **Default**: `[]`
- **Description**: Custom DNS servers for the community
- **Examples**: 
  - `[]` (uses Azure default DNS)
  - `['8.8.8.8', '8.8.4.4']` (custom DNS servers)

#### Approval Settings

All approval settings accept two values:
- **`'Required'`**: Approval workflow is mandatory
- **`'NotRequired'`**: Action can be performed without approval (default)

##### Resource Management Approvals

| Setting | Description | Default |
|---------|-------------|---------|
| `enclaveCreation` | Approval for creating virtual enclaves | `'NotRequired'` |
| `enclaveDeletion` | Approval for deleting virtual enclaves | `'NotRequired'` |
| `connectionCreation` | Approval for creating enclave connections | `'NotRequired'` |
| `connectionDeletion` | Approval for deleting enclave connections | `'NotRequired'` |
| `connectionUpdate` | Approval for updating enclave connections | `'NotRequired'` |
| `endpointCreation` | Approval for creating endpoints | `'NotRequired'` |
| `endpointDeletion` | Approval for deleting endpoints | `'NotRequired'` |
| `endpointUpdate` | Approval for updating endpoints | `'NotRequired'` |
| `maintenanceMode` | Approval for toggling maintenance mode | `'NotRequired'` |
| `serviceCatalogDeployment` | Approval for service catalog deployments | `'NotRequired'` |

##### Notification Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `notificationOnApprovalCreation` | Send notification when approval request is created | `'NotRequired'` |
| `notificationOnApprovalAction` | Send notification when approval action is taken | `'NotRequired'` |
| `notificationOnApprovalDeletion` | Send notification when approval request is deleted | `'NotRequired'` |

##### Approver Configuration

##### `minimumApproversRequired`
- **Type**: `int`
- **Default**: `1`
- **Description**: Minimum number of approvers required for approval requests

##### `mandatoryApprovers`
- **Type**: `array`
- **Default**: `[]`
- **Description**: List of mandatory approvers
- **Format**: 
```json
[
  {
    "approverEntraId": "12345678-1234-1234-1234-123456789012"
  }
]
```

### Virtual Enclave Configuration (`enclaveConfig`)

The `enclaveConfig` object controls network and security settings for virtual enclaves.

#### Security Settings

##### `bastionEnabled`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Deploy Azure Bastion for secure RDP/SSH access
- **Note**: Eliminates need for public IPs on workload resources

#### Network Settings

##### `networkName`
- **Type**: `string`
- **Default**: `'enclave-vnet'`
- **Description**: Name for the virtual network

##### Network Size Options (Choose One)

###### Option 1: `networkSize` (Automatic CIDR)
- **Type**: `string`
- **Default**: `'/24'`
- **Description**: Network size for automatic CIDR allocation
- **Examples**: `'/24'` (254 hosts), `'/23'` (510 hosts), `'/22'` (1022 hosts)

###### Option 2: `customCidrRange` (Manual CIDR)
- **Type**: `string`
- **Optional**: Yes
- **Description**: Manual CIDR range specification
- **Example**: `'10.1.0.0/24'`
- **Note**: Use instead of `networkSize` for specific CIDR requirements

##### Communication Settings

##### `allowSubnetCommunication`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Allow communication between subnets within the enclave

##### `connectToAzureServices`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Enable connectivity to Azure platform services

#### Optional Settings

##### `diagnosticDestination`
- **Type**: `string`
- **Optional**: Yes
- **Values**: `'EnclaveOnly'` | `'Both'`
- **Description**: Controls where enclave diagnostic information is sent. If omitted or an invalid value is supplied, the module falls back to the module parameter `diagnosticDestinationDefault` (default `'Both'`).
- **Default**: Not specified (module defaults to `'Both'`)

### Tags Configuration (`tags`)

Standard Azure resource tags applied to all deployed resources.

```bicep
tags: {
  Environment: 'Virtual-Enclave'
  Project: 'Azure-Virtual-Enclave'
  DeployedBy: 'Bicep'
}
```

## Example Configurations

### Minimal Development Setup
```bicep
baseName: 'dev-ave'
numberOfCommunities: 1
numberOfEnclavesPerCommunity: 1
numberOfWorkloadsPerEnclave: 2
```

### Production Multi-Community Setup
```bicep
baseName: 'prod-ave'
numberOfCommunities: 3
numberOfEnclavesPerCommunity: 2
numberOfWorkloadsPerEnclave: 5
communityConfigs: [
  // Production Community
  {
    addressSpace: '10.0.0.0/16'
    dnsServers: []
    approvalSettings: {
      enclaveCreation: 'Required'
      enclaveDeletion: 'Required'
      minimumApproversRequired: 3
      mandatoryApprovers: [
        { approverEntraId: 'prod-security-team-guid' }
      ]
    }
  }
  // Staging Community  
  {
    addressSpace: '10.1.0.0/16'
    dnsServers: ['8.8.8.8', '8.8.4.4']
    approvalSettings: {
      enclaveCreation: 'Required'
      enclaveDeletion: 'Required'
      minimumApproversRequired: 2
      mandatoryApprovers: []
    }
  }
  // Development Community
  {
    addressSpace: '10.2.0.0/16'
    dnsServers: []
    approvalSettings: {
      enclaveCreation: 'NotRequired'
      enclaveDeletion: 'NotRequired'
      minimumApproversRequired: 1
      mandatoryApprovers: []
    }
  }
]
```

### High-Security Environment
```bicep
numberOfCommunities: 2
communityConfigs: [
  // High-Security Production Community
  {
    addressSpace: '172.16.0.0/16'
    dnsServers: ['internal-dns-1', 'internal-dns-2']
    approvalSettings: {
      enclaveCreation: 'Required'
      enclaveDeletion: 'Required'
      connectionCreation: 'Required'
      connectionDeletion: 'Required'
      connectionUpdate: 'Required'
      maintenanceMode: 'Required'
      serviceCatalogDeployment: 'Required'
      notificationOnApprovalCreation: 'Required'
      notificationOnApprovalAction: 'Required'
      minimumApproversRequired: 3
      mandatoryApprovers: [
        { approverEntraId: 'security-team-guid' },
        { approverEntraId: 'compliance-team-guid' }
      ]
    }
  }
  // Isolated Compliance Community
  {
    addressSpace: '172.17.0.0/16'
    dnsServers: []
    approvalSettings: {
      enclaveCreation: 'Required'
      enclaveDeletion: 'Required'
      connectionCreation: 'Required'
      connectionDeletion: 'Required'
      connectionUpdate: 'Required'
      maintenanceMode: 'Required'
      serviceCatalogDeployment: 'Required'
      notificationOnApprovalCreation: 'Required'
      notificationOnApprovalAction: 'Required'
      minimumApproversRequired: 2
      mandatoryApprovers: [
        { approverEntraId: 'compliance-officer-guid' }
      ]
    }
  }
]
enclaveConfig: {
  bastionEnabled: true
  allowSubnetCommunication: false
  connectToAzureServices: false
}
```

## Best Practices

1. **Start Small**: Begin with minimal configurations for development/testing
2. **Plan Network Topology**: Ensure CIDR ranges don't overlap with existing networks
3. **Security by Design**: Enable appropriate approval workflows for production environments
4. **Mandatory Approvers**: Use Entra ID group IDs rather than individual user IDs for flexibility
5. **Tags**: Implement consistent tagging strategy for cost management and governance
6. **Bastion**: Always enable Bastion for production environments to avoid public IP exposure

## Deployment Limits

- **Communities**: 1-10 per deployment
- **Enclaves**: 1-5 per community
- **Workloads**: 1-10 per enclave
- **Maximum Total Resources**: 500 workloads per deployment (10×5×10)

## Support and Troubleshooting

For issues with Azure Virtual Enclave deployment:

1. Verify the Microsoft.Mission resource provider is registered in your subscription
2. Ensure appropriate permissions for creating communities and virtual enclaves
3. Check Azure region availability for AVE services
4. Review approval workflows if resources aren't being created as expected