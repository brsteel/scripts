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

@description('Number of Azure Virtual Enclave communities to deploy (1-10). Must match length(communityConfigs). Typical deployments use 1; increase only when you need strict separation (e.g. multi-mission staging, distinct governance).')
@minValue(1)
@maxValue(10)
param numberOfCommunities int = 1

// Note: communityConfigs array must have exactly numberOfCommunities entries

// Note: The following simple parameters are used for validation and loops
// Actual enclave and workload configurations are defined within each community's config

// Removed deprecated scalar enclave/workload count parameters; counts now derived from nested configuration.

@description('Enable governedServiceList emission (uses built-in defaults when true).')
param enableGovernedServiceList bool = false

@description('Default diagnostic destination applied when an enclave does not specify one (CommunityOnly | EnclaveOnly | Both).')
@allowed([
  'CommunityOnly'
  'EnclaveOnly'
  'Both'
])
param diagnosticDestinationDefault string = 'Both'

@description('Principal object IDs (users, groups, service principals) to assign Contributor at all scopes (community, enclave, workload). Empty = no automatic contributor assignments.')
param contributorPrincipals array = []

// Additional (optional) role bucket principal arrays; empty arrays mean no assignments
@description('Community Reader group/object IDs')
param communityReaders array = []
@description('Community Network Contributor group/object IDs')
param communityNetworkContributors array = []
@description('Community Monitoring Reader group/object IDs')
param communityMonitoringReaders array = []
@description('Community Monitoring Contributor group/object IDs')
param communityMonitoringContributors array = []
@description('Community Log Analytics Reader group/object IDs')
param communityLogAnalyticsReaders array = []
@description('Community Log Analytics Contributor group/object IDs')
param communityLogAnalyticsContributors array = []
@description('Community Security Reader group/object IDs')
param communitySecurityReaders array = []
@description('Community Security Admin group/object IDs')
param communitySecurityAdmins array = []
@description('Community User Access Administrator group/object IDs')
param communityUserAccessAdministrators array = []


// Maintenance validation (simple guardrail) - if any community maintenance object sets mode On but missing justification, template could be extended to fail (future enhancement)

@description('Array of community configurations with nested enclave and workload configurations.')
param communityConfigs array = [
  // Community 0 (default / primary). Add additional objects to this array when numberOfCommunities > 1.
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
    communityContributors: contributorPrincipals
    communityReaders: communityReaders
    communityNetworkContributors: communityNetworkContributors
    communityMonitoringReaders: communityMonitoringReaders
    communityMonitoringContributors: communityMonitoringContributors
    communityLogAnalyticsReaders: communityLogAnalyticsReaders
    communityLogAnalyticsContributors: communityLogAnalyticsContributors
    communitySecurityReaders: communitySecurityReaders
    communitySecurityAdmins: communitySecurityAdmins
    communityUserAccessAdministrators: communityUserAccessAdministrators
    enableGovernedServiceList: enableGovernedServiceList
    diagnosticDestinationDefault: diagnosticDestinationDefault
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
// Simplified totalResources output (derived enclave/workload counts omitted due to current Bicep aggregation limitations)
output totalResources object = {
  communities: numberOfCommunities
  deployEnclaves: deployEnclaves
}

// Hierarchical RBAC summary (array of community summaries)
output rbacSummary array = [for i in range(0, numberOfCommunities): communities[i].outputs.rbacSummary]

output effectiveLocation string = canonicalLocation
