@description('The Azure region where resources will be deployed')
param location string

@description('Name of the AVE community')
param communityName string

@description('Community configuration with nested enclave and workload configurations')
param communityConfig object

@description('Tags to apply to all resources')
param tags object

// Optional pre-created Entra ID group object IDs for community-level RBAC (empty arrays = no assignment)
@description('Object IDs for Community Contributors group (optional)')
param communityContributors array = []
@description('Object IDs for Community Readers group (optional)')
param communityReaders array = []
@description('Object IDs for Community Network Contributors group (optional)')
param communityNetworkContributors array = []
@description('Object IDs for Community Monitoring Readers group (optional)')
param communityMonitoringReaders array = []
@description('Object IDs for Community Monitoring Contributors group (optional)')
param communityMonitoringContributors array = []
@description('Object IDs for Community Log Analytics Readers group (optional)')
param communityLogAnalyticsReaders array = []
@description('Object IDs for Community Log Analytics Contributors group (optional)')
param communityLogAnalyticsContributors array = []
@description('Object IDs for Community Security Readers group (optional)')
param communitySecurityReaders array = []
@description('Object IDs for Community Security Admins group (optional)')
param communitySecurityAdmins array = []
@description('Object IDs for Community User Access Administrators group (optional)')
param communityUserAccessAdministrators array = []

// -----------------------------------------------------------------------------
// Governed Service List (Portal Defaults)
// All services: option Allow, policyAction Enforce, enforcement Enabled
// Exception: Monitoring -> option NotApplicable (still enforcement Enabled per portal view)
// Exposed with feature toggle & override capability.
@description('Enable emission of the governedServiceList into the community properties')
param enableGovernedServiceList bool = false

@description('Override entries for governedServiceList (match on serviceId). Each object may include serviceId, option, policyAction, enforcement.')
param governedServiceListOverrides array = []

@description('Default diagnostic destination propagated to enclaves if they omit diagnosticDestination (CommunityOnly | EnclaveOnly | Both).')
@allowed([
  'CommunityOnly'
  'EnclaveOnly'
  'Both'
])
param diagnosticDestinationDefault string = 'Both'

// NOTE: Object comprehension (map) syntax may not be supported in current Bicep version in this environment.
// We'll merge overrides using array filtering instead of constructing a map.

// Portal default governed services baseline
var defaultGovernedServiceList = [
  { serviceId: 'AKS',              option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'AppService',       option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'ContainerRegistry',option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'CosmosDB',         option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'KeyVault',         option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'MicrosoftSQL',     option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'Monitoring',       option: 'NotApplicable', policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'PostgreSQL',       option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'ServiceBus',       option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'Storage',          option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'AzureFirewalls',   option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'Insights',         option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'Logic',            option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'PrivateDNSZones',  option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
  { serviceId: 'DataConnectors',   option: 'Allow',         policyAction: 'Enforce', enforcement: 'Enabled' }
]
// Effective list: overrides replace defaults entirely if provided (simplified behavior)
var effectiveGovernedServiceList = length(governedServiceListOverrides) > 0 ? governedServiceListOverrides : defaultGovernedServiceList

// Fragment only emitted when enable flag set
var governedServiceListFragment = enableGovernedServiceList ? { governedServiceList: effectiveGovernedServiceList } : {}

@description('When false, enclaves (and workloads) are skipped for phased deployments')
param deployEnclaves bool = true

// Inline RBAC data structures removed (RP rejected inline assignments). Using standard roleAssignments resources instead.

// Maintenance principals (if supplied)
var maintenancePrincipals = [for p in (communityConfig.?maintenance.?principals ?? []): { id: p, type: 'Group' }]

// Maintenance mode object (only include justification when On and provided)
var communityMaintenanceMode = union(
  {
    mode: (empty(communityConfig.?maintenance.?mode) ? 'Off' : communityConfig.maintenance.mode)
    principals: (length(maintenancePrincipals) > 0 && communityConfig.?maintenance.?mode != 'Off') ? maintenancePrincipals : []
  },
  (communityConfig.?maintenance.?mode == 'On' && !empty(communityConfig.?maintenance.?justification)) ? { justification: communityConfig.maintenance.justification } : {}
)

resource aveCommnity 'Microsoft.Mission/communities@2025-05-01-preview' = {
  name: communityName
  location: location
  tags: tags
  identity: {
    type: 'None'
  }
  properties: union({
      addressSpace: communityConfig.addressSpace
      dnsServers: communityConfig.dnsServers
      // approvalSettings intentionally omitted (US Gov RP validation issue)
      maintenanceModeConfiguration: communityMaintenanceMode
    }, governedServiceListFragment)
}

// Role map (GUIDs only) for built-in roles used in AVE portal
var roleMap = {
  Contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  NetworkContributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'
  MonitoringReader: '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
  MonitoringContributor: '749f88d5-cbae-40b8-bcfc-e573ddc772fa'
  LogAnalyticsReader: '73c42c96-874c-492b-b04d-ab87d138a893'
  LogAnalyticsContributor: '92aaf0da-9dab-42b6-94a3-d43ce8d16293'
  SecurityReader: '8d32ff11-19e7-4f25-8d7a-4176c81c0f83'
  SecurityAdmin: 'fb1c8493-542b-48eb-b624-b4c8fea62acd'
  UserAccessAdministrator: '18d7d88d-d35e-4fb5-a5c3-7773a3e3d1af'
}

// Helper to build roleDefinitionId
// Build full roleDefinitionId inside each assignment (no lambda functions in Bicep variable scope)

// Community-scope role assignments (one loop per role bucket). Only created when arrays non-empty.
resource communityContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communityContributors: {
  name: guid(aveCommnity.id, roleMap.Contributor, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.Contributor)
    principalId: principal
  }
}]
resource communityReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communityReaders: {
  name: guid(aveCommnity.id, roleMap.Reader, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.Reader)
    principalId: principal
  }
}]
resource communityNetworkContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communityNetworkContributors: {
  name: guid(aveCommnity.id, roleMap.NetworkContributor, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.NetworkContributor)
    principalId: principal
  }
}]
resource communityMonitoringReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communityMonitoringReaders: {
  name: guid(aveCommnity.id, roleMap.MonitoringReader, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.MonitoringReader)
    principalId: principal
  }
}]
resource communityMonitoringContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communityMonitoringContributors: {
  name: guid(aveCommnity.id, roleMap.MonitoringContributor, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.MonitoringContributor)
    principalId: principal
  }
}]
resource communityLogReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communityLogAnalyticsReaders: {
  name: guid(aveCommnity.id, roleMap.LogAnalyticsReader, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.LogAnalyticsReader)
    principalId: principal
  }
}]
resource communityLogContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communityLogAnalyticsContributors: {
  name: guid(aveCommnity.id, roleMap.LogAnalyticsContributor, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.LogAnalyticsContributor)
    principalId: principal
  }
}]
resource communitySecurityReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communitySecurityReaders: {
  name: guid(aveCommnity.id, roleMap.SecurityReader, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.SecurityReader)
    principalId: principal
  }
}]
resource communitySecurityAdminAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communitySecurityAdmins: {
  name: guid(aveCommnity.id, roleMap.SecurityAdmin, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.SecurityAdmin)
    principalId: principal
  }
}]
resource communityUserAccessAdminAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in communityUserAccessAdministrators: {
  name: guid(aveCommnity.id, roleMap.UserAccessAdministrator, principal)
  scope: aveCommnity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleMap.UserAccessAdministrator)
    principalId: principal
  }
}]

// Per-enclave effective RBAC arrays: allow enclaveConfig.rbac overrides (if provided); fallback to community arrays
var enclaveConfigs = communityConfig.enclaveConfigs
// Clearable inheritance: presence of property (even empty array) is treated as explicit override.
var _enclaveEffective = [for enc in enclaveConfigs: {
  contributors: contains(enc, 'rbac') && contains(enc.rbac, 'contributors') ? (enc.rbac.contributors ?? []) : communityContributors
  readers: contains(enc, 'rbac') && contains(enc.rbac, 'readers') ? (enc.rbac.readers ?? []) : communityReaders
  networkContributors: contains(enc, 'rbac') && contains(enc.rbac, 'networkContributors') ? (enc.rbac.networkContributors ?? []) : communityNetworkContributors
  monitoringReaders: contains(enc, 'rbac') && contains(enc.rbac, 'monitoringReaders') ? (enc.rbac.monitoringReaders ?? []) : communityMonitoringReaders
  monitoringContributors: contains(enc, 'rbac') && contains(enc.rbac, 'monitoringContributors') ? (enc.rbac.monitoringContributors ?? []) : communityMonitoringContributors
  logReaders: contains(enc, 'rbac') && contains(enc.rbac, 'logReaders') ? (enc.rbac.logReaders ?? []) : communityLogAnalyticsReaders
  logContributors: contains(enc, 'rbac') && contains(enc.rbac, 'logContributors') ? (enc.rbac.logContributors ?? []) : communityLogAnalyticsContributors
  securityReaders: contains(enc, 'rbac') && contains(enc.rbac, 'securityReaders') ? (enc.rbac.securityReaders ?? []) : communitySecurityReaders
  securityAdmins: contains(enc, 'rbac') && contains(enc.rbac, 'securityAdmins') ? (enc.rbac.securityAdmins ?? []) : communitySecurityAdmins
  userAccessAdministrators: contains(enc, 'rbac') && contains(enc.rbac, 'userAccessAdministrators') ? (enc.rbac.userAccessAdministrators ?? []) : communityUserAccessAdministrators
}]

// Deploy Virtual Enclaves within the community using nested configurations
module virtualEnclaves 'ave-enclave.bicep' = [for (enclaveConfig, i) in (deployEnclaves ? communityConfig.enclaveConfigs : []): {
  name: 'ave-enclave-${i}'
  params: {
    location: location
    enclaveName: '${communityName}e${i}'
    communityResourceId: aveCommnity.id
    enclaveConfig: enclaveConfig
    tags: union(tags, { EnclaveIndex: string(i) })
    enclaveContributors: _enclaveEffective[i].contributors
    enclaveReaders: _enclaveEffective[i].readers
    enclaveNetworkContributors: _enclaveEffective[i].networkContributors
    enclaveMonitoringReaders: _enclaveEffective[i].monitoringReaders
    enclaveMonitoringContributors: _enclaveEffective[i].monitoringContributors
    enclaveLogAnalyticsReaders: _enclaveEffective[i].logReaders
    enclaveLogAnalyticsContributors: _enclaveEffective[i].logContributors
    enclaveSecurityReaders: _enclaveEffective[i].securityReaders
    enclaveSecurityAdmins: _enclaveEffective[i].securityAdmins
    enclaveUserAccessAdministrators: _enclaveEffective[i].userAccessAdministrators
    diagnosticDestinationDefault: diagnosticDestinationDefault
  }
}]

// Outputs
output communityName string = aveCommnity.name
output communityResourceId string = aveCommnity.id
output managedResourceGroupName string = aveCommnity.properties.managedResourceGroupName
output deployedEnclaves array = [for (enclaveConfig, i) in (deployEnclaves ? communityConfig.enclaveConfigs : []): {
  name: '${communityName}e${i}'
  resourceId: deployEnclaves ? virtualEnclaves[i].outputs.enclaveResourceId : ''
}]

// Surface maintenance mapping (for audit clients) – principals & justification not applied directly due to unknown schema
output communityMaintenance object = {
  mode: empty(communityConfig.?maintenance.?mode) ? 'Off' : communityConfig.maintenance.mode
  principals: (length(communityConfig.?maintenance.?principals ?? []) > 0) ? communityConfig.maintenance.principals : []
  justification: (communityConfig.?maintenance.?mode == 'On') ? (communityConfig.?maintenance.?justification ?? '') : ''
}

// RBAC summary (community + each enclave effective arrays)
var _enclaveSummaries = [for (enc, i) in enclaveConfigs: {
  name: '${communityName}e${i}'
  effective: _enclaveEffective[i]
}]
output rbacSummary object = {
  community: {
    name: communityName
    contributors: communityContributors
    readers: communityReaders
    networkContributors: communityNetworkContributors
    monitoringReaders: communityMonitoringReaders
    monitoringContributors: communityMonitoringContributors
    logReaders: communityLogAnalyticsReaders
    logContributors: communityLogAnalyticsContributors
    securityReaders: communitySecurityReaders
    securityAdmins: communitySecurityAdmins
    userAccessAdministrators: communityUserAccessAdministrators
  }
  enclaves: _enclaveSummaries
}
