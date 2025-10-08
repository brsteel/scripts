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
@maxLength(28) // 28 + 'c9' (2 chars) = 30 max community name length (portal limit)
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
// Portal hard limit: AVE community resource name must be <= 30 characters.
// We now use baseName directly (no numeric suffix). If deploying multiple communities you must vary baseName values manually.
var communityNameLengthLimit = 30
var longestCommunityName = baseName
var longestEnclaveName = '${baseName}e0'
var communityNameWithinLimit = length(longestCommunityName) <= communityNameLengthLimit
var enclaveNameWithinLimit = length(longestEnclaveName) <= communityNameLengthLimit
output hostedNameAnalysis object = {
  baseName: baseName
  projectedCommunityHostedRgLength: projectedCommunityHostedRgLength
  projectedEnclaveHostedRgLength: projectedEnclaveHostedRgLength
  portalCommunityNameLimit: communityNameLengthLimit
  longestCommunityName: longestCommunityName
  longestCommunityNameLength: length(longestCommunityName)
  longestEnclaveName: longestEnclaveName
  longestEnclaveNameLength: length(longestEnclaveName)
  communityNameWithinLimit: communityNameWithinLimit
  enclaveNameWithinLimit: enclaveNameWithinLimit
}

// Single-community template: communityConfigs must contain exactly one object

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

@description('Community configuration (single object) with nested enclave and workload configurations.')
param communityConfig object = {
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

// Single community; nested enclaves/workloads configured above

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

// Deploy single AVE Community using native Microsoft.Mission resources
module community 'modules/ave-community.bicep' = {
  name: 'ave-community'
  scope: mainResourceGroup
  params: {
    location: canonicalLocation
    communityName: baseName
    deployEnclaves: deployEnclaves
    communityConfig: communityConfig
    tags: tags
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
}

// Outputs
output resourceGroupName string = mainResourceGroup.name
output communityResourceId string = community.outputs.communityResourceId
output totalResources object = {
  communities: 1
  deployEnclaves: deployEnclaves
}
// rbacSummary from module is already an array; pass through directly
output rbacSummary object = community.outputs.rbacSummary

output effectiveLocation string = canonicalLocation
// Aggregated maintenance validation output (community + enclaves)
output maintenanceValidation object = {
  community: community.outputs.communityMaintenanceValidation
  enclaves: community.outputs.enclaveMaintenanceValidations
  // anyFailures computation omitted due to module output evaluation timing limits; compute externally if needed
  anyFailures: community.outputs.communityMaintenanceValidation.status == 'Fail'
}
