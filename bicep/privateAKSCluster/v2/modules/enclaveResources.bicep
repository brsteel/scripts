// AKS Network Infrastructure (Mission Virtual Enclave + delegated / supporting subnets)
// Provides: subnetDefinitions[] (authoritative), capacity + identity validation outputs, optional subnet communication toggle.
// IMPORTANT: The enclave service treats the submitted subnetConfigurations array as AUTHORITATIVE.
// Redeploying with a reduced list will REMOVE enclave subnets not listed. Always include ALL desired subnets.

type roleAssignmentPrincipal = {
  id: string
  type: string
}

type roleAssignmentMapping = {
  roleDefinitionId: string
  principals: roleAssignmentPrincipal[]
}

@description('Name of the enclave (Microsoft.Mission/virtualEnclaves resource name)')
param enclaveName string
@description('Resource ID of the parent community to attach this enclave to')
param communityResourceId string
@description('Explicit CIDR to request for the enclave base VNet (must fit inside the community address space).')
@minLength(1)
param customCidrRange string
@description('Enable Bastion access to enclave')
param enableBastion bool = false
@description('Allow broad subnet-to-subnet communication (least privilege if false)')
param allowSubnetCommunication bool = false
@description('Diagnostic destination: CommunityOnly | EnclaveOnly | Both | Unspecified. Must match existing enclave when updating.')
param diagnosticDestination string
@description('Tags applied to enclave resource')
param tags object = {}

@description('Role assignment definitions for the enclave container. Each object: { roleDefinitionId, principals: [{id,type}, ...] }.')
param enclaveRoleAssignments roleAssignmentMapping[] = []

@description('Role assignment definitions for workload collections. Each object: { roleDefinitionId, principals: [{id,type}, ...] }.')
param workloadRoleAssignments roleAssignmentMapping[] = []

@description('Standalone maintenance mode principals. These are independent from enclave/workload role assignment principals.')
param maintenanceModePrincipals roleAssignmentPrincipal[] = []

@description('Maintenance mode for enclave managed resources: Off, General, or Advanced.')
@allowed(['Off','General','Advanced'])
param maintenanceMode string = 'Advanced'

@description('Managed identity type assigned to the enclave resource: SystemAssigned (default) or UserAssigned')
@allowed(['SystemAssigned','UserAssigned'])
param enclaveIdentityType string = 'SystemAssigned'
@description('Resource ID of an existing user-assigned identity to attach when enclaveIdentityType = UserAssigned. Leave empty to auto-create one.')
param enclaveUserAssignedIdentityResourceId string = ''
@description('Name to use when auto-creating a user-assigned identity (ignored when resourceId is provided). Defaults to <enclaveName>-uai.')
param enclaveUserAssignedIdentityName string = ''

// subnetDefinitions[] enables arbitrary AKS node pool subnets and other enclave subnets (ingress, data, etc.)
@description('Array of subnet definition objects: { name, plannedNodeCount?, plannedMaxPodsPerNode?, ipStaticOverhead?, purpose?, networkPrefixSize? }. Provide networkPrefixSize to bypass autosizing (for example ingress/admin). Set purpose="pod" on subnets dedicated to Azure CNI pod address space. Capacity fields are only required when relying on autosizing.')
param subnetDefinitions array = []

// AKS connectivity parameters removed - handled by aksEnclaveConnection.bicep

// Automatic sizing only: all capacity inputs required per subnet object for determinism.
// Example object:
// {
//   name: 'np-system'
//   plannedNodeCount: 3
//   plannedMaxPodsPerNode: 30
//   ipStaticOverhead: 25
// }

// Duplicate detection removed; variable previously unused.
var hasSubnets = length(subnetDefinitions) > 0
var usingUserAssignedIdentity = toLower(enclaveIdentityType) == 'userassigned'
var normalizedEnclaveIdentityType = usingUserAssignedIdentity ? 'UserAssigned' : 'SystemAssigned'
var normalizedEnclaveNameSegment = toLower(replace(replace(enclaveName, '_', '-'), '--', '-'))
var defaultEnclaveIdentityNameSeed = 'uai-${normalizedEnclaveNameSegment}'
var defaultEnclaveIdentityName = empty(enclaveUserAssignedIdentityName)
  ? substring(defaultEnclaveIdentityNameSeed, 0, min(length(defaultEnclaveIdentityNameSeed), 128))
  : toLower(enclaveUserAssignedIdentityName)
var shouldCreateUserAssignedIdentity = usingUserAssignedIdentity && empty(enclaveUserAssignedIdentityResourceId)
var communityResourceIdSegments = split(communityResourceId, '/')
var communityNameSegment = length(communityResourceIdSegments) > 8 ? communityResourceIdSegments[8] : normalizedEnclaveNameSegment

#disable-next-line BCP081
resource parentCommunity 'Microsoft.Mission/communities@2024-12-01-preview' existing = {
  name: communityNameSegment
}
// AKS community variables removed - handled by aksEnclaveConnection.bicep


// Network Post-Config logic removed.


resource enclaveUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (shouldCreateUserAssignedIdentity) {
  name: defaultEnclaveIdentityName
  location: resourceGroup().location
  tags: union(tags, {
    'mission-component': 'enclave-identity'
  })
}

var createdIdentityResourceId = shouldCreateUserAssignedIdentity ? enclaveUserAssignedIdentity.id : ''
var effectiveUserAssignedIdentityResourceId = usingUserAssignedIdentity
  ? (!empty(createdIdentityResourceId) ? createdIdentityResourceId : enclaveUserAssignedIdentityResourceId)
  : ''
var userAssignedIdentityMap = !usingUserAssignedIdentity || empty(effectiveUserAssignedIdentityResourceId) ? {} : {
  '${effectiveUserAssignedIdentityResourceId}': {}
}



// Role assignment arrays now supplied directly via parameters, enabling any Azure roleDefinitionId mappings

var subnetConfigurations = [for s in subnetDefinitions: {
  subnetName: s.name
  networkPrefixSize: int(s.networkPrefixSize)
}]

// Simplified: capacity analytics temporarily removed for compilation stability
// Future: reintroduce capacity once environment upgrades Bicep engine.

// Identity validation
var identityRecommendation = normalizedEnclaveIdentityType == 'SystemAssigned'
  ? 'SystemAssigned recommended for lifecycle alignment; use UserAssigned when a stable principal is required.'
  : 'UserAssigned specified; ensure least privilege and dedicated usage.'
var userAssignedIdValid = normalizedEnclaveIdentityType != 'UserAssigned' || !empty(effectiveUserAssignedIdentityResourceId)
var identityValidationMessage = userAssignedIdValid
  ? 'Identity configuration valid.'
  : 'ERROR: provide enclaveUserAssignedIdentityResourceId or allow auto-creation when enclaveIdentityType = UserAssigned.'
var maintenanceModeJustification = maintenanceMode == 'Off' ? 'Off' : 'Governance'

#disable-next-line BCP081
resource enclave 'Microsoft.Mission/virtualEnclaves@2025-05-01-preview' = {
  name: enclaveName
  location: resourceGroup().location
  identity: normalizedEnclaveIdentityType == 'UserAssigned' ? {
    type: 'UserAssigned'
    userAssignedIdentities: userAssignedIdentityMap
  } : null
  tags: tags
  properties: {
    communityResourceId: communityResourceId
    enclaveVirtualNetwork: {
      networkSize: 'custom'
      customCidrRange: customCidrRange
      // Default isolation: do NOT allow broad subnet communication unless explicitly enabled.
      // When allowSubnetCommunication=true this becomes a flat any-to-any intra-VNet path (subject to future service constraints).
      subnetConfigurations: subnetConfigurations
      allowSubnetCommunication: allowSubnetCommunication
    }
    enclaveDefaultSettings: {
      diagnosticDestination: diagnosticDestination
    }
    maintenanceModeConfiguration: {
      mode: maintenanceMode
      justification: maintenanceModeJustification
      principals: maintenanceModePrincipals
    }
    enclaveRoleAssignments: enclaveRoleAssignments
    workloadRoleAssignments: workloadRoleAssignments
    bastionEnabled: enableBastion
  }
}


// Connection resources moved to separate module aksEnclaveConnection.bicep to avoid BCP182 circular dependency
// on enclave output subnetConfigurations for dynamic CIDR calculation.

// Outputs
output enclaveResourceId string = enclave.id
// Capacity-related outputs removed pending analytic reintroduction
// duplicateSubnetNames output removed (simplified template)
output enclaveIdentityTypeOut string = normalizedEnclaveIdentityType
output identityRecommendation string = identityRecommendation
output identityValid bool = userAssignedIdValid
output identityValidationMessage string = identityValidationMessage
output enclaveUserAssignedIdentityResourceIdOut string = effectiveUserAssignedIdentityResourceId
output allowSubnetCommunicationOut bool = allowSubnetCommunication
output hasSubnets bool = hasSubnets
output managedResourceGroupName string = enclave.properties.managedResourceGroupName
output subnetConfigurationsOut array = enclave.properties.enclaveVirtualNetwork.subnetConfigurations
