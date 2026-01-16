targetScope = 'subscription'

@description('Subscription ID where the AKS workload resource group will be created. Defaults to the current deployment subscription.')
param targetSubscriptionId string = subscription().subscriptionId

@description('Resource ID of the existing Microsoft.Mission/virtualEnclaves resource that will host this workload.')
param enclaveResourceId string

@minLength(1)
@description('Name of the workload to create under the enclave.')
param workloadName string

@description('Name of the AKS workload resource group that will host AKS-dependent resources. Defaults to <workloadName>-rg.')
param aksResourceGroupName string = toLower('${workloadName}-rg')

@description('Azure region for the AKS workload resource group. Defaults to the enclave location.')
param aksResourceGroupLocation string = ''

@description('Tags applied to the workload resource.')
param tags object = {}

@description('AKS network overlay selection. flatLegacy = single subnet for nodes+pods, azureCniPodSubnet = Azure CNI with dedicated pod subnet, azureCniOverlay = Azure CNI overlay where pods use overlay CIDR.')
@allowed(['flatLegacy','azureCniPodSubnet','azureCniOverlay'])
param aksNetworkOverlay string = 'flatLegacy'

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

var enclaveSegments = split(enclaveResourceId, '/')
var enclaveSubscriptionId = length(enclaveSegments) > 2 ? enclaveSegments[2] : subscription().subscriptionId
var enclaveName = length(enclaveSegments) > 8 ? enclaveSegments[8] : ''
var enclaveResourceGroupName = length(enclaveSegments) > 4 ? enclaveSegments[4] : ''

resource enclave 'Microsoft.Mission/virtualEnclaves@2025-05-01-preview' existing = {
  name: enclaveName
  scope: resourceGroup(enclaveSubscriptionId, enclaveResourceGroupName)
}

var resolvedManagedResourceGroupName = empty(managedResourceGroupName) ? enclave.properties.managedResourceGroupName : managedResourceGroupName

var workloadLocation = enclave.location
var workloadResourceGroupLocation = empty(aksResourceGroupLocation) ? deployment().location : aksResourceGroupLocation
var workloadResourceGroupId = subscriptionResourceId(targetSubscriptionId, 'Microsoft.Resources/resourceGroups', aksResourceGroupName)

resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: aksResourceGroupName
  location: workloadResourceGroupLocation
  tags: tags
}

module aveWorkloadModule './modules/aveWorkload.bicep' = {
  name: 'workload-${uniqueString(workloadName)}'
  scope: resourceGroup(enclaveSubscriptionId, enclaveResourceGroupName)
  params: {
    enclaveName: enclaveName
    workloadName: workloadName
    location: workloadLocation
    workloadResourceGroupId: workloadResourceGroupId
    tags: tags
  }
  dependsOn: [
    workloadResourceGroup
  ]
}

var computedNetworkConfig = aksNetworkOverlay == 'azureCniOverlay' ? {
  networkPlugin: 'azure'
  networkPluginMode: 'overlay'
  podCidr: '10.244.0.0/16'
} : {
  networkPlugin: 'azure'
  networkPluginMode: null
}

var resolvedAksDefinition = union(computedNetworkConfig, aksDefinition)

module aksWorkloadResources './modules/aksWorkloadResources.bicep' = {
  name: 'aks-resources-${uniqueString(workloadName)}'
  scope: resourceGroup(targetSubscriptionId, aksResourceGroupName)
  params: {
    workloadName: workloadName
    location: workloadResourceGroupLocation
    enclaveResourceId: enclaveResourceId
    tags: tags
    communityManagedResourceGroupResourceId: communityManagedResourceGroupResourceId
    aksDefinition: resolvedAksDefinition
    keyVaultDefinition: keyVaultDefinition
    storageDefinition: storageDefinition
    managedResourceGroupName: resolvedManagedResourceGroupName
  }
  dependsOn: [
    workloadResourceGroup
  ]
}

output workloadResourceId string = aveWorkloadModule.outputs.workloadResourceId
output workloadResourceGroupId string = workloadResourceGroupId
