@description('The Azure region where resources will be deployed')
param location string

@description('Name of the virtual enclave')
param enclaveName string

@description('Community resource ID that this enclave belongs to')
param communityResourceId string

@description('Enclave configuration with nested workload configurations')
param enclaveConfig object

@description('Tags to apply to all resources')
param tags object

// -----------------------------------------------------------------------------
// Guardrail Validation (manual since Bicep assert feature is not enabled)
var _normalizedNetworkSize = toLower(empty(enclaveConfig.?networkSize) ? '' : enclaveConfig.networkSize)
var _isCustom = _normalizedNetworkSize == 'custom'
var _needsCustomButMissing = _isCustom && empty(enclaveConfig.?customCidrRange)
var _hasRangeButNotCustom = !_isCustom && !empty(enclaveConfig.?customCidrRange)
var _maintenanceOnMissingJustification = (toLower(enclaveConfig.?maintenance.?mode ?? 'off') == 'on') && empty(enclaveConfig.?maintenance.?justification)
// Validation failure message (evaluated if triggered)
var _validationFailed = _needsCustomButMissing || _hasRangeButNotCustom || _maintenanceOnMissingJustification

// Build validation message parts safely (avoid inline complex string interpolation that ARM transpiler struggled with)
var _validationParts = concat(
  _needsCustomButMissing ? ['customCidrRange required when networkSize==custom'] : [],
  _hasRangeButNotCustom ? ['customCidrRange must be omitted unless networkSize==custom'] : [],
  _maintenanceOnMissingJustification ? ['maintenance.justification required when maintenance.mode==On'] : []
)
var _validationMessage = _validationFailed ? 'Enclave configuration validation failed: ${join(_validationParts, ' | ')}' : ''

@description('Default diagnostic destination when enclaveConfig.diagnosticDestination is not provided. Per-enclave override must be one of the allowed values.')
@allowed([
  'CommunityOnly'
  'EnclaveOnly'
  'Both'
])
param diagnosticDestinationDefault string = 'Both'

// Enclave maintenance configuration now read from enclaveConfig.maintenance (mode, principals, justification)

// Optional pre-created Entra ID group object IDs for enclave scope
@description('Object IDs for Enclave Contributors group (optional)')
param enclaveContributors array = []
@description('Object IDs for Enclave Readers group (optional)')
param enclaveReaders array = []
@description('Object IDs for Enclave Network Contributors group (optional)')
param enclaveNetworkContributors array = []
@description('Object IDs for Enclave Monitoring Readers group (optional)')
param enclaveMonitoringReaders array = []
@description('Object IDs for Enclave Monitoring Contributors group (optional)')
param enclaveMonitoringContributors array = []
@description('Object IDs for Enclave Log Analytics Readers group (optional)')
param enclaveLogAnalyticsReaders array = []
@description('Object IDs for Enclave Log Analytics Contributors group (optional)')
param enclaveLogAnalyticsContributors array = []
@description('Object IDs for Enclave Security Readers group (optional)')
param enclaveSecurityReaders array = []
@description('Object IDs for Enclave Security Admins group (optional)')
param enclaveSecurityAdmins array = []
@description('Object IDs for Enclave User Access Administrators group (optional)')
param enclaveUserAccessAdministrators array = []

// Optional pre-created groups for workloads (to control workload container operations specifically)
// Workload-level RBAC params removed from enclave module; now passed directly into workload module via inheritance logic there.

// Inline RBAC role assignment scaffolding removed (RP rejected inline payload). Using standard roleAssignments resources.
// Removed unused empty fragments

// Maintenance principals
var maintenancePrincipals = [for p in (enclaveConfig.?maintenance.?principals ?? []): { id: p, type: 'Group' }]
var enclaveMaintenanceMode = union(
  {
    mode: (empty(enclaveConfig.?maintenance.?mode) ? 'Off' : enclaveConfig.maintenance.mode)
    principals: (length(maintenancePrincipals) > 0 && enclaveConfig.?maintenance.?mode != 'Off') ? maintenancePrincipals : []
  },
  (enclaveConfig.?maintenance.?mode == 'On' && !empty(enclaveConfig.?maintenance.?justification)) ? { justification: enclaveConfig.maintenance.justification } : {}
)

// Deploy Azure Virtual Enclave using native Microsoft.Mission resource
resource virtualEnclave 'Microsoft.Mission/virtualEnclaves@2025-05-01-preview' = {
  name: enclaveName
  location: location
  tags: tags
  identity: {
    type: 'None'
  }
  properties: union({
      communityResourceId: communityResourceId
      bastionEnabled: enclaveConfig.bastionEnabled
      enclaveVirtualNetwork: {
        networkName: enclaveConfig.networkName
        // Normalize networkSize; if not provided default 24. Only send customCidrRange when networkSize == 'custom'.
        networkSize: (!empty(enclaveConfig.?networkSize) ? (toLower(enclaveConfig.networkSize) == 'custom' ? 'custom' : replace(enclaveConfig.networkSize, '/', '')) : '24')
        allowSubnetCommunication: bool(enclaveConfig.?allowSubnetCommunication)
        // customCidrRange conditional per API rule
        // (Cannot specify customCidrRange if NetworkSize is not 'custom')
        ...(toLower(enclaveConfig.?networkSize) == 'custom' && !empty(enclaveConfig.?customCidrRange) ? { customCidrRange: enclaveConfig.customCidrRange } : {})
        subnetConfigurations: [
          {
            subnetName: 'workload-subnet'
            networkPrefixSize: 26
          }
          {
            subnetName: 'management-subnet'
            networkPrefixSize: 28
          }
        ]
      }
      enclaveDefaultSettings: {
        // Per-enclave override honored when valid; otherwise falls back to module default
        diagnosticDestination: contains(['CommunityOnly','EnclaveOnly','Both'], enclaveConfig.?diagnosticDestination) ? enclaveConfig.diagnosticDestination : diagnosticDestinationDefault
      }
      maintenanceModeConfiguration: enclaveMaintenanceMode
  }, (_validationFailed ? { validationError: _validationMessage } : {}))
}

// Standard RBAC at enclave scope (Contributor only, mirroring community contributor set)
var contributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','b24988ac-6180-42a0-ab88-20f7382dd24c')
resource enclaveContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveContributors: {
  name: guid(virtualEnclave.id, contributorRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: contributorRoleDefinitionId
    principalId: principal
  }
}]

// Additional role definition IDs
var readerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','acdd72a7-3385-48ef-bd42-f606fba81ae7')
var networkContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','4d97b98b-1d4f-4787-a291-c67834d212e7')
var monitoringReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','43d0d8ad-25c7-4714-9337-8ba259a9fe05')
var monitoringContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','749f88d5-cbae-40b8-bcfc-e573ddc772fa')
var logReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','73c42c96-874c-492b-b04d-ab87d138a893')
var logContributorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','92aaf0da-9dab-42b6-94a3-d43ce8d16293')
var securityReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','8d32ff11-19e7-4f25-8d7a-4176c81c0f83')
var securityAdminRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','fb1c8493-542b-48eb-b624-b4c8fea62acd')
var userAccessAdminRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','18d7d88d-d35e-4fb5-a5c3-7773a3e3d1af')

// Enclave scope assignments for additional roles
resource enclaveReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveReaders: {
  name: guid(virtualEnclave.id, readerRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: readerRoleDefinitionId
    principalId: principal
  }
}]
resource enclaveNetworkContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveNetworkContributors: {
  name: guid(virtualEnclave.id, networkContributorRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: networkContributorRoleDefinitionId
    principalId: principal
  }
}]
resource enclaveMonitoringReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveMonitoringReaders: {
  name: guid(virtualEnclave.id, monitoringReaderRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: monitoringReaderRoleDefinitionId
    principalId: principal
  }
}]
resource enclaveMonitoringContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveMonitoringContributors: {
  name: guid(virtualEnclave.id, monitoringContributorRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: monitoringContributorRoleDefinitionId
    principalId: principal
  }
}]
resource enclaveLogReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveLogAnalyticsReaders: {
  name: guid(virtualEnclave.id, logReaderRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: logReaderRoleDefinitionId
    principalId: principal
  }
}]
resource enclaveLogContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveLogAnalyticsContributors: {
  name: guid(virtualEnclave.id, logContributorRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: logContributorRoleDefinitionId
    principalId: principal
  }
}]
resource enclaveSecurityReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveSecurityReaders: {
  name: guid(virtualEnclave.id, securityReaderRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: securityReaderRoleDefinitionId
    principalId: principal
  }
}]
resource enclaveSecurityAdminAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveSecurityAdmins: {
  name: guid(virtualEnclave.id, securityAdminRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: securityAdminRoleDefinitionId
    principalId: principal
  }
}]
resource enclaveUserAccessAdminAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in enclaveUserAccessAdministrators: {
  name: guid(virtualEnclave.id, userAccessAdminRoleDefinitionId, principal)
  scope: virtualEnclave
  properties: {
    roleDefinitionId: userAccessAdminRoleDefinitionId
    principalId: principal
  }
}]

// Workload-level role assignments (scoped to enclave for now OR can be changed to each workload resource after module deployment). For precision, we'll create them at workload resource level: modify workload module instead for per-workload scoping.
// Contributor assignments for workloads already handled by workload module parameters; other roles passed similarly.

// Deploy AVE Workloads within the enclave using nested configurations
module workloads 'ave-workload.bicep' = [for (workloadConfig, i) in enclaveConfig.workloadConfigs: {
  // Include enclaveName in deployment name to ensure uniqueness across enclaves
  name: 'ave-${enclaveName}-workload-${i}'
  params: {
    location: location
    workloadName: workloadConfig.?name ?? '${enclaveName}-workload-${i}'
    parentEnclaveName: virtualEnclave.name
    workloadConfig: workloadConfig  // Pass individual workload config
    tags: union(tags, {
      WorkloadIndex: string(i)
    })
    // Inherit RBAC arrays from enclave scope so workloads get same contributor (and any future) assignments unless overridden in workloadConfig.rbac
    workloadContributors: enclaveContributors
    workloadReaders: enclaveReaders
    workloadNetworkContributors: enclaveNetworkContributors
    workloadMonitoringReaders: enclaveMonitoringReaders
    workloadMonitoringContributors: enclaveMonitoringContributors
    workloadLogAnalyticsReaders: enclaveLogAnalyticsReaders
    workloadLogAnalyticsContributors: enclaveLogAnalyticsContributors
    workloadSecurityReaders: enclaveSecurityReaders
    workloadSecurityAdmins: enclaveSecurityAdmins
    workloadUserAccessAdministrators: enclaveUserAccessAdministrators
  }
}]

// Outputs
output enclaveName string = virtualEnclave.name
output enclaveResourceId string = virtualEnclave.id
output managedResourceGroupName string = virtualEnclave.properties.managedResourceGroupName
output deployedWorkloads array = [for (workloadConfig, i) in enclaveConfig.workloadConfigs: {
  name: workloadConfig.?name ?? '${enclaveName}-workload-${i}'
  resourceId: workloads[i].outputs.workloadResourceId
}]

output workloadRbacSummary array = [for (workloadConfig, i) in enclaveConfig.workloadConfigs: {
  name: workloadConfig.?name ?? '${enclaveName}-workload-${i}'
  effective: workloads[i].outputs.workloadRbacEffective
}]

output enclaveMaintenance object = {
  mode: empty(enclaveConfig.?maintenance.?mode) ? 'Off' : enclaveConfig.maintenance.mode
  principals: (length(enclaveConfig.?maintenance.?principals ?? []) > 0) ? enclaveConfig.maintenance.principals : []
  justification: (enclaveConfig.?maintenance.?mode == 'On') ? (enclaveConfig.?maintenance.?justification ?? '') : ''
}
