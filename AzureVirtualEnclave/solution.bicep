targetScope = 'subscription'

/*
Azure Virtual Enclave (AVE) Deployment Template
===============================================

This template deploys Azure Virtual Enclave infrastructure using the native Microsoft.Mission resource provider.
It creates a scalable architecture with N communities, M enclaves per community, and O workloads per enclave.

Key Features:
- Native Azure Virtual Enclave resources (Microsoft.Mission/*)
- Built-in Azure Bastion for secure access (no public IPs on workloads)
- Comprehensive approval workflows and governance settings
- Managed identities and role-based access control
- Configurable network topology and security settings

Resource Hierarchy:
Community -> Virtual Enclave -> Workload (container objects)

For detailed parameter documentation, see the individual parameter descriptions below.
*/

@description('The Azure region where resources will be deployed')
param location string = deployment().location

@description('Base name for the deployment. MUST be short because the RP creates hosted RGs like <name>-HostedResources-<nonce>.')
@minLength(3)
@maxLength(24)
param baseName string


@description('When false, enclaves (and workloads) are skipped – deploy communities only (for phased troubleshooting).')
param deployEnclaves bool = true

// Always normalize to canonical Azure region format (lowercase, no spaces) to match portal behavior and avoid RP inconsistencies
var canonicalLocation = toLower(replace(location, ' ', ''))

// ---- Name Length Guardrails --------------------------------------------------
// Verbose pattern: <base>-community-<ci>-enclave-<ei>
// Compact pattern: <base>c<ci>e<ei>
// Name inflation (documentation aid only): hosted RG adds ~30 chars. With max baseName=24 this leaves ample headroom.
var projectedCommunityHostedRgLength = length('${baseName}c0') + 30
var projectedEnclaveHostedRgLength   = length('${baseName}c0e0') + 30
output hostedNameAnalysis object = {
  baseName: baseName
  projectedCommunityHostedRgLength: projectedCommunityHostedRgLength
  projectedEnclaveHostedRgLength: projectedEnclaveHostedRgLength
}

@description('Number of Azure Virtual Enclave communities to deploy (1-10). Must match the length of communityConfigs array.')
@minValue(1)
@maxValue(10)
param numberOfCommunities int = 2

// Note: communityConfigs array must have exactly numberOfCommunities entries

// Note: The following simple parameters are used for validation and loops
// Actual enclave and workload configurations are defined within each community's config

@description('DEPRECATED: Use enclaveConfigs array within each community instead. Kept for backward compatibility.')
@minValue(1)
@maxValue(5)
param numberOfEnclavesPerCommunity int = 2

@description('DEPRECATED: Use workloadConfigs array within each enclave instead. Kept for backward compatibility.')
@minValue(1)
@maxValue(10)
param numberOfWorkloadsPerEnclave int = 3

@description('Array of community configurations with nested enclave and workload configurations.')
param communityConfigs array = [
  // Community 0 - Development Environment
  {
    // Community-level Network Configuration - MUST be unique per community
    addressSpace: '10.0.0.0/16'
    dnsServers: []
    
    // approvalSettings omitted (RP validation issue)
    
    // Enclave configurations within this community
    enclaveConfigs: [
      // Enclave 0 - Web Tier
      {
        bastionEnabled: true
        networkName: 'web-tier-vnet'
        networkSize: '/24'
        customCidrRange: '10.0.0.0/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        diagnosticDestination: 'EnclaveOnly'
        
        // Workload configurations within this enclave
        workloadConfigs: [
          {
            name: 'web-server-1'
            resourceGroupCollection: ['rg-web-primary']
            // Additional workload-specific properties can be added here
          }
          {
            name: 'web-server-2'
            resourceGroupCollection: ['rg-web-secondary']
          }
        ]
      }
      // Enclave 1 - App Tier  
      {
        bastionEnabled: false  // No direct access to app tier
        networkName: 'app-tier-vnet'
        networkSize: '/24'
        customCidrRange: '10.0.1.0/24'
        allowSubnetCommunication: false  // More restrictive
        connectToAzureServices: true
        diagnosticDestination: 'Both'
        
        workloadConfigs: [
          {
            name: 'app-server-1'
            resourceGroupCollection: ['rg-app-primary']
          }
        ]
      }
    ]
  }
]

// Note: Enclave and workload configurations are now nested within communityConfigs array
// This allows for individual configuration of each enclave and workload

@description('Tags to apply to all resources')
param tags object = {
  Environment: 'Virtual-Enclave'
  Project: 'Azure-Virtual-Enclave'
  DeployedBy: 'Bicep'
}

// Resource Group for the entire deployment
resource mainResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${baseName}-rg'
  location: canonicalLocation
  tags: tags
}

// Deploy AVE Communities using native Microsoft.Mission resources
module communities 'modules/ave-community.bicep' = [for i in range(0, numberOfCommunities): {
  name: 'ave-community-${i}'
  scope: mainResourceGroup
  params: {
    location: canonicalLocation
  communityName: '${baseName}c${i}'
  // useCompactNames removed; always compact
    deployEnclaves: deployEnclaves
    communityConfig: communityConfigs[i]  // Pass entire community config with nested enclaves/workloads
    tags: union(tags, { CommunityIndex: string(i) })
  }
}]

// Outputs
output resourceGroupName string = mainResourceGroup.name
output deployedCommunities array = [for i in range(0, numberOfCommunities): {
  name: '${baseName}c${i}'
  resourceGroupName: mainResourceGroup.name
  location: canonicalLocation
  resourceId: communities[i].outputs.communityResourceId
}]
output totalResources object = {
  communities: numberOfCommunities
  // Nominal (configured) counts based on legacy scalar params
  configuredEnclaves: numberOfCommunities * numberOfEnclavesPerCommunity
  configuredWorkloads: numberOfCommunities * numberOfEnclavesPerCommunity * numberOfWorkloadsPerEnclave
  // Actual deployed (may be 0 if deployEnclaves = false)
  enclavesDeployed: deployEnclaves ? numberOfCommunities * numberOfEnclavesPerCommunity : 0
  workloadsDeployed: deployEnclaves ? numberOfCommunities * numberOfEnclavesPerCommunity * numberOfWorkloadsPerEnclave : 0
}

output effectiveLocation string = canonicalLocation
