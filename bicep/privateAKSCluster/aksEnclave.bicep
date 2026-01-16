targetScope = 'subscription'

@description('Name of the resource group to create for the enclave.')
param aveResourceGroupName string

@description('Location for the resource group and resources.')
param location string = deployment().location

// Pass-through parameters for aksNetworkInfra.bicep
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
param enclaveRoleAssignments array = []

@description('Role assignment definitions for workload collections. Each object: { roleDefinitionId, principals: [{id,type}, ...] }.')
param workloadRoleAssignments array = []

@description('Managed identity type assigned to the enclave resource: SystemAssigned (default) or UserAssigned')
@allowed(['SystemAssigned','UserAssigned'])
param enclaveIdentityType string = 'SystemAssigned'
@description('Resource ID of an existing user-assigned identity to attach when enclaveIdentityType = UserAssigned. Leave empty to auto-create one.')
param enclaveUserAssignedIdentityResourceId string = ''
@description('Name to use when auto-creating a user-assigned identity (ignored when resourceId is provided). Defaults to <enclaveName>-uai.')
param enclaveUserAssignedIdentityName string = ''

@description('Array of subnet definition objects.')
param subnetDefinitions array = []

@description('Automatically create the AVE community endpoint and enclave connection required for AKS outbound connectivity.')
param enableAksRequiredConnectivity bool = true

@description('Comma-separated list of CIDR ranges to use for the AKS community connection source. Leave empty to default to customCidrRange.')
param aksRequiredSourceCidrs string = ''

@description('Optional list of subnet names to dynamically resolve to CIDR ranges for the AKS community connection source. If provided, overrides aksRequiredSourceCidrs.')
param aksRequiredSourceSubnetNames array = []

@description('Optional override for the generated AKS community endpoint definition.')
param aksRequiredEndpointDefinition object = {}

@description('Optional override for the generated AKS community connection definition.')
param aksRequiredConnectionDefinition object = {}

@description('Additional community endpoint + connection objects to create.')
param aksUserDefinedNetworkDefinitions array = []

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: aveResourceGroupName
  location: location
  tags: tags
}

module enclaveInfra 'modules/enclaveResources.bicep' = {
  name: 'enclave-infra-${uniqueString(enclaveName)}'
  scope: rg
  params: {
    enclaveName: enclaveName
    communityResourceId: communityResourceId
    customCidrRange: customCidrRange
    enableBastion: enableBastion
    allowSubnetCommunication: allowSubnetCommunication
    diagnosticDestination: diagnosticDestination
    tags: tags
    enclaveRoleAssignments: enclaveRoleAssignments
    workloadRoleAssignments: workloadRoleAssignments
    enclaveIdentityType: enclaveIdentityType
    enclaveUserAssignedIdentityResourceId: enclaveUserAssignedIdentityResourceId
    enclaveUserAssignedIdentityName: enclaveUserAssignedIdentityName
    subnetDefinitions: subnetDefinitions
  }
}

module aksConnection 'modules/aksEnclaveConnection.bicep' = if (enableAksRequiredConnectivity) {
  name: 'enclave-connection-${uniqueString(enclaveName)}'
  scope: rg
  params: {
    enclaveName: enclaveName
    enclaveResourceId: enclaveInfra.outputs.enclaveResourceId
    communityResourceId: communityResourceId
    customCidrRange: customCidrRange
    tags: tags
    enableAksRequiredConnectivity: enableAksRequiredConnectivity
    aksRequiredSourceCidrs: aksRequiredSourceCidrs
    aksRequiredSourceSubnetNames: aksRequiredSourceSubnetNames
    aksRequiredEndpointDefinition: aksRequiredEndpointDefinition
    aksRequiredConnectionDefinition: aksRequiredConnectionDefinition
    aksUserDefinedNetworkDefinitions: aksUserDefinedNetworkDefinitions
    subnetConfigurations: enclaveInfra.outputs.subnetConfigurationsOut
  }
}

output enclaveResourceId string = enclaveInfra.outputs.enclaveResourceId
