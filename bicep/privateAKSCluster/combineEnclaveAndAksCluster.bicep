targetScope = 'subscription'

// --------------------------------------------------------------------------------
// ENCLAVE PARAMETERS
// --------------------------------------------------------------------------------

@description('Name of the resource group to create for the Enclave.')
param aveResourceGroupName string

@description('Location for the enclave resource group and resources.')
param location string = deployment().location

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

@description('Tags applied to enclave and workload resources')
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

@description('AKS network overlay selection.')
@allowed(['flatLegacy','azureCniPodSubnet','azureCniOverlay'])
param aksNetworkOverlay string = 'flatLegacy'

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

// --------------------------------------------------------------------------------
// WORKLOAD PARAMETERS
// --------------------------------------------------------------------------------

@description('Subscription ID where the AKS workload resource group will be created. Defaults to the current deployment subscription.')
param targetSubscriptionId string = subscription().subscriptionId

@description('Name of the workload to create under the enclave.')
@minLength(1)
param workloadName string

@description('Name of the AKS workload resource group that will host AKS-dependent resources. Defaults to <workloadName>-rg.')
param aksResourceGroupName string = toLower('${workloadName}-rg')

@description('Azure region for the AKS workload resource group. Defaults to the enclave location.')
param aksResourceGroupLocation string = ''

@secure()
@description('AKS configuration overrides (cluster, networking, diagnostics, identity). Empty object applies defaults derived from the workload name and enclave inputs.')
param aksDefinition object = {}

@description('Key Vault configuration overrides for the workload stack (name, SKU, DNS, private endpoint subnet).')
param keyVaultDefinition object = {}

@description('Storage account configuration overrides for the workload stack (name, SKU, DNS, private endpoint subnet).')
param storageDefinition object = {}

@description('Name of the enclave-managed resource group that hosts the enclave virtual network and shared resources. If not provided, it will be looked up from the enclave resource.')
param managedResourceGroupName string = ''

@description('Resource ID of the community managed resource group meant to host the firewall')
param communityManagedResourceGroupResourceId string

@description('Resource ID of the Resource Group where Private DNS Zones should be created/linked. If empty, defaults to the AKS workload resource group.')
param privateDnsResourceGroupId string = ''

// --------------------------------------------------------------------------------
// MODULES
// --------------------------------------------------------------------------------

module enclaveDeployment 'aksEnclave.bicep' = {
  name: 'deploy-enclave-${uniqueString(enclaveName)}'
  scope: subscription(targetSubscriptionId)
  params: {
    aveResourceGroupName: aveResourceGroupName
    location: location
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
    enableAksRequiredConnectivity: enableAksRequiredConnectivity
    aksRequiredSourceCidrs: aksRequiredSourceCidrs
    aksRequiredSourceSubnetNames: aksRequiredSourceSubnetNames
    aksRequiredEndpointDefinition: aksRequiredEndpointDefinition
    aksRequiredConnectionDefinition: aksRequiredConnectionDefinition
    aksUserDefinedNetworkDefinitions: aksUserDefinedNetworkDefinitions
  }
}

module workloadDeployment 'aksClusterWorkload.bicep' = {
  name: 'deploy-workload-${uniqueString(workloadName)}'
  scope: subscription(targetSubscriptionId)
  params: {
    targetSubscriptionId: targetSubscriptionId
    enclaveResourceId: enclaveDeployment.outputs.enclaveResourceId
    workloadName: workloadName
    aksResourceGroupName: aksResourceGroupName
    aksResourceGroupLocation: aksResourceGroupLocation
    tags: tags
    aksNetworkOverlay: aksNetworkOverlay
    communityManagedResourceGroupResourceId: communityManagedResourceGroupResourceId
    aksDefinition: aksDefinition
    keyVaultDefinition: keyVaultDefinition
    storageDefinition: storageDefinition
    managedResourceGroupName: managedResourceGroupName
    privateDnsResourceGroupId: privateDnsResourceGroupId
  }
}

output enclaveResourceId string = enclaveDeployment.outputs.enclaveResourceId
output workloadResourceId string = workloadDeployment.outputs.workloadResourceId
