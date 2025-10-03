# Nested Configuration Guide for Azure Virtual Enclave

This guide explains the new **nested configuration structure** that allows individual configuration of communities, enclaves, and workloads.

## Overview

The template now supports **three levels of configuration**:

```
Community Level
├── Approval settings, network addressing, DNS
├── Enclave Level
│   ├── Network configuration, bastion settings, diagnostics
│   └── Workload Level
│       └── Resource group collections, custom properties
```

## Configuration Structure

### Community Configuration (`communityConfigs` array)

Each community has its own configuration object with nested enclave configurations:

```bicep
communityConfigs: [
  {
    // Community-level settings
    addressSpace: '10.0.0.0/16'    // MUST be unique per community
    dnsServers: []                 // Community DNS servers
    approvalSettings: { ... }      // Community governance settings
    
    // Nested enclave configurations
    enclaveConfigs: [
      {
        // Enclave-level settings
        bastionEnabled: true
        networkName: 'web-tier'
        networkSize: '/24'
        customCidrRange: '10.0.0.0/24'
        
        // Nested workload configurations  
        workloadConfigs: [
          {
            name: 'web-frontend'
            resourceGroupCollection: ['rg-web']
          }
        ]
      }
    ]
  }
]
```

### Enclave Configuration Properties

Each enclave within a community can have unique settings:

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `bastionEnabled` | bool | Deploy Azure Bastion | `true` |
| `networkName` | string | Virtual network name | `'web-tier-vnet'` |
| `networkSize` | string | Auto-allocated CIDR size | `'/24'`, `'/23'` |
| `customCidrRange` | string | Manual CIDR specification | `'10.0.1.0/24'` |
| `allowSubnetCommunication` | bool | Inter-subnet communication | `true` |
| `connectToAzureServices` | bool | Azure service connectivity | `true` |
| `diagnosticDestination` | string | Diagnostic routing | `'EnclaveOnly'`, `'Both'` |
| `workloadConfigs` | array | Nested workload configurations | See below |

### Workload Configuration Properties

Each workload within an enclave can have unique settings:

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `name` | string | Custom workload name (optional) | `'web-frontend'` |
| `resourceGroupCollection` | array | Resource groups for this workload | `['rg-web', 'rg-shared']` |

## Configuration Examples

### 1. Simple Development Environment

Single community with basic web application:

```bicep
numberOfCommunities: 1
communityConfigs: [
  {
    addressSpace: '10.0.0.0/16'
    dnsServers: []
    approvalSettings: {
      enclaveCreation: 'NotRequired'
      // ... other settings with 'NotRequired'
    }
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkName: 'dev-vnet'
        networkSize: '/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        workloadConfigs: [
          {
            name: 'dev-app'
            resourceGroupCollection: ['rg-dev-app']
          }
        ]
      }
    ]
  }
]
```

### 2. Multi-Tier Application

Community with separate web, app, and database tiers:

```bicep
numberOfCommunities: 1
communityConfigs: [
  {
    addressSpace: '10.0.0.0/16'
    dnsServers: []
    approvalSettings: { /* ... */ }
    enclaveConfigs: [
      // Web Tier Enclave
      {
        bastionEnabled: true              // Admin access allowed
        networkName: 'web-tier'
        customCidrRange: '10.0.0.0/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        workloadConfigs: [
          {
            name: 'web-frontend'
            resourceGroupCollection: ['rg-web-frontend']
          },
          {
            name: 'web-api'
            resourceGroupCollection: ['rg-web-api']
          }
        ]
      },
      // Application Tier Enclave
      {
        bastionEnabled: false             // No direct access
        networkName: 'app-tier'
        customCidrRange: '10.0.1.0/24'
        allowSubnetCommunication: false   // More restrictive
        connectToAzureServices: true
        workloadConfigs: [
          {
            name: 'app-services'
            resourceGroupCollection: ['rg-app-primary', 'rg-app-cache']
          }
        ]
      },
      // Database Tier Enclave
      {
        bastionEnabled: false             // No direct access
        networkName: 'db-tier'
        customCidrRange: '10.0.2.0/24'
        allowSubnetCommunication: false   // Highly restrictive
        connectToAzureServices: true
        diagnosticDestination: 'Both'     // Enhanced monitoring
        workloadConfigs: [
          {
            name: 'primary-db'
            resourceGroupCollection: ['rg-db-primary']
          },
          {
            name: 'backup-db'
            resourceGroupCollection: ['rg-db-backup']
          }
        ]
      }
    ]
  }
]
```

### 3. Multi-Environment Setup

Development, staging, and production communities:

```bicep
numberOfCommunities: 3
communityConfigs: [
  // Development Community
  {
    addressSpace: '10.0.0.0/16'
    dnsServers: []
    approvalSettings: {
      enclaveCreation: 'NotRequired'
      // ... relaxed settings
    }
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkName: 'dev-all-in-one'
        networkSize: '/23'              // Larger network for dev
        allowSubnetCommunication: true
        connectToAzureServices: true
        workloadConfigs: [
          { name: 'dev-web', resourceGroupCollection: ['rg-dev-web'] },
          { name: 'dev-api', resourceGroupCollection: ['rg-dev-api'] },
          { name: 'dev-db', resourceGroupCollection: ['rg-dev-db'] }
        ]
      }
    ]
  },
  // Staging Community
  {
    addressSpace: '10.1.0.0/16'
    dnsServers: ['8.8.8.8']
    approvalSettings: {
      enclaveCreation: 'Required'
      // ... moderate restrictions
    }
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkName: 'staging-vnet'
        networkSize: '/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        diagnosticDestination: 'Both'
        workloadConfigs: [
          { name: 'staging-app', resourceGroupCollection: ['rg-staging-app'] },
          { name: 'staging-db', resourceGroupCollection: ['rg-staging-db'] }
        ]
      }
    ]
  },
  // Production Community
  {
    addressSpace: '10.2.0.0/16'
    dnsServers: ['internal-dns-1', 'internal-dns-2']
    approvalSettings: {
      enclaveCreation: 'Required'
      enclaveDeletion: 'Required'
      minimumApproversRequired: 2
      // ... strict governance
    }
    enclaveConfigs: [
      // Separate enclaves for production tiers
      {
        bastionEnabled: true
        networkName: 'prod-web'
        customCidrRange: '10.2.0.0/24'
        allowSubnetCommunication: false
        connectToAzureServices: true
        workloadConfigs: [
          { name: 'prod-web-primary', resourceGroupCollection: ['rg-prod-web-1'] },
          { name: 'prod-web-secondary', resourceGroupCollection: ['rg-prod-web-2'] }
        ]
      },
      {
        bastionEnabled: false
        networkName: 'prod-app'
        customCidrRange: '10.2.1.0/24'
        allowSubnetCommunication: false
        connectToAzureServices: true
        workloadConfigs: [
          { name: 'prod-app', resourceGroupCollection: ['rg-prod-app'] }
        ]
      }
    ]
  }
]
```

## Migration from Simple Configuration

If you have existing templates using the old simple configuration:

### Old Structure (Deprecated)
```bicep
numberOfCommunitiesPerCommunity: 2
numberOfWorkloadsPerEnclave: 3
enclaveConfig: {
  bastionEnabled: true
  networkSize: '/24'
}
```

### New Structure (Current)
```bicep
communityConfigs: [
  {
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkSize: '/24'
        workloadConfigs: [
          { resourceGroupCollection: [] },
          { resourceGroupCollection: [] },
          { resourceGroupCollection: [] }
        ]
      },
      {
        bastionEnabled: true
        networkSize: '/24'
        workloadConfigs: [
          { resourceGroupCollection: [] },
          { resourceGroupCollection: [] },
          { resourceGroupConfigs: [] }
        ]
      }
    ]
  }
]
```

## Best Practices

### Network Planning
- **Unique CIDR ranges**: Each enclave needs non-overlapping `customCidrRange`
- **Size appropriately**: Use `/24` for small enclaves, `/23` for larger ones
- **Plan hierarchy**: Community → Enclave → Subnet addressing

### Security Configuration  
- **Bastion placement**: Enable only on enclaves needing admin access
- **Network isolation**: Use `allowSubnetCommunication: false` for sensitive tiers
- **Diagnostic routing**: Use `'Both'` for critical enclaves, `'EnclaveOnly'` for others

### Workload Organization
- **Logical grouping**: Group related resources in same workload
- **Resource group strategy**: Use separate RGs per service or environment
- **Naming convention**: Use consistent naming like `'tier-service-instance'`

### Governance Settings
- **Environment alignment**: Development = permissive, Production = restrictive
- **Approval workflows**: More approvals for production communities
- **Notification strategy**: Enable notifications for production changes

## Validation Rules

The template validates:
- ✅ `communityConfigs` array length matches `numberOfCommunities`
- ✅ Each community has unique `addressSpace`
- ✅ Each enclave within community has unique CIDR ranges
- ✅ All required properties are specified

## Common Patterns

### Pattern 1: Environment Separation
```bicep
// Dev community: permissive, single enclave
// Staging community: moderate restrictions, single enclave  
// Prod community: strict governance, multiple enclaves
```

### Pattern 2: Tier Separation
```bicep
// Single community with multiple enclaves per tier
// Web tier: public-facing, bastion enabled
// App tier: internal, no bastion
// Data tier: highly restricted, enhanced monitoring
```

### Pattern 3: Service Isolation
```bicep
// Each microservice gets its own enclave
// Shared services in separate enclaves
// Cross-service communication through controlled interfaces
```

This nested configuration approach provides maximum flexibility while maintaining clear separation of concerns at each level of the Azure Virtual Enclave hierarchy.