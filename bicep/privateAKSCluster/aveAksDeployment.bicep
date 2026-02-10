targetScope = 'subscription'

// --------------------------------------------------------------------------------
// PARAMETERS
// --------------------------------------------------------------------------------

@description('Core deployment context (subscription, location, tags).')
param deploymentContext object

@description('Configuration for the enclave resources.')
param enclaveConfiguration object

@description('Configuration for network connectivity (endpoints and connections).')
param connectivityConfiguration object

@description('Configuration for the workload and AKS cluster.')
param workloadConfiguration object

// --------------------------------------------------------------------------------
// VARIABLES
// --------------------------------------------------------------------------------

var tags = contains(deploymentContext, 'tags') ? deploymentContext.tags : {}
var location = contains(deploymentContext, 'location') && !empty(deploymentContext.location) ? deploymentContext.location : deployment().location
var targetSubscriptionId = contains(deploymentContext, 'subscriptionId') && !empty(deploymentContext.subscriptionId) ? deploymentContext.subscriptionId : subscription().subscriptionId

// Enclave Params
var existingEnclaveResourceId = contains(enclaveConfiguration, 'existingResourceId') ? enclaveConfiguration.existingResourceId : ''
var deployEnclave = empty(existingEnclaveResourceId)

var aveResourceGroupName = contains(enclaveConfiguration, 'resourceGroupName') ? enclaveConfiguration.resourceGroupName : ''
var enclaveName = contains(enclaveConfiguration, 'name') ? enclaveConfiguration.name : ''
var communityResourceId = contains(enclaveConfiguration, 'communityResourceId') ? enclaveConfiguration.communityResourceId : ''
var customCidrRange = contains(enclaveConfiguration, 'customCidrRange') ? enclaveConfiguration.customCidrRange : ''
var enableBastion = contains(enclaveConfiguration, 'enableBastion') ? enclaveConfiguration.enableBastion : false
var allowSubnetCommunication = contains(enclaveConfiguration, 'allowSubnetCommunication') ? enclaveConfiguration.allowSubnetCommunication : false
var diagnosticDestination = contains(enclaveConfiguration, 'diagnosticDestination') ? enclaveConfiguration.diagnosticDestination : 'EnclaveOnly'
var enclaveRoleAssignments = contains(enclaveConfiguration, 'roleAssignments') ? enclaveConfiguration.roleAssignments : []
var identityConfig = contains(enclaveConfiguration, 'identity') ? enclaveConfiguration.identity : { type: 'SystemAssigned' }
var enclaveIdentityType = contains(identityConfig, 'type') ? identityConfig.type : 'SystemAssigned'
var enclaveUserAssignedIdentityResourceId = contains(identityConfig, 'userAssignedResourceId') ? identityConfig.userAssignedResourceId : ''
var enclaveUserAssignedIdentityName = contains(identityConfig, 'userAssignedName') ? identityConfig.userAssignedName : ''
var subnetDefinitions = contains(enclaveConfiguration, 'subnetDefinitions') ? enclaveConfiguration.subnetDefinitions : []

// Connectivity Params
var enableAksRequiredConnectivity = contains(connectivityConfiguration, 'enableAksRequiredConnectivity') ? connectivityConfiguration.enableAksRequiredConnectivity : true
var aksRequiredSourceCidrs = contains(connectivityConfiguration, 'aksRequiredSourceCidrs') ? connectivityConfiguration.aksRequiredSourceCidrs : ''
var aksRequiredSourceSubnetNames = contains(connectivityConfiguration, 'aksRequiredSourceSubnetNames') ? connectivityConfiguration.aksRequiredSourceSubnetNames : []
var aksRequiredEndpointDefinition = contains(connectivityConfiguration, 'aksRequiredEndpointDefinition') ? connectivityConfiguration.aksRequiredEndpointDefinition : {}
var aksRequiredConnectionDefinition = contains(connectivityConfiguration, 'aksRequiredConnectionDefinition') ? connectivityConfiguration.aksRequiredConnectionDefinition : {}
var aksUserDefinedNetworkDefinitions = contains(connectivityConfiguration, 'aksUserDefinedNetworkDefinitions') ? connectivityConfiguration.aksUserDefinedNetworkDefinitions : []

// Workload Params
var workloadName = workloadConfiguration.name
var aksResourceGroupName = contains(workloadConfiguration, 'resourceGroupName') && !empty(workloadConfiguration.resourceGroupName) ? workloadConfiguration.resourceGroupName : toLower('${workloadName}-rg')
var aksResourceGroupLocation = contains(workloadConfiguration, 'location') && !empty(workloadConfiguration.location) ? workloadConfiguration.location : location
var workloadRoleAssignments = contains(workloadConfiguration, 'roleAssignments') ? workloadConfiguration.roleAssignments : []
var aksNetworkOverlay = contains(workloadConfiguration, 'aksNetworkOverlay') ? workloadConfiguration.aksNetworkOverlay : 'flatLegacy'
var managedResourceGroupName = contains(workloadConfiguration, 'managedResourceGroupName') ? workloadConfiguration.managedResourceGroupName : ''
var communityManagedResourceGroupResourceId = workloadConfiguration.communityManagedResourceGroupResourceId
var privateDnsResourceGroupId = contains(workloadConfiguration, 'privateDnsResourceGroupId') ? workloadConfiguration.privateDnsResourceGroupId : ''
var aksDefinition = contains(workloadConfiguration, 'aksDefinition') ? workloadConfiguration.aksDefinition : {}
var keyVaultDefinition = contains(workloadConfiguration, 'keyVaultDefinition') ? workloadConfiguration.keyVaultDefinition : {}
var storageDefinition = contains(workloadConfiguration, 'storageDefinition') ? workloadConfiguration.storageDefinition : {}


// --------------------------------------------------------------------------------
// MODULES
// --------------------------------------------------------------------------------

module enclaveDeployment 'modules/aksEnclave.bicep' = if (deployEnclave) {
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

var finalEnclaveResourceId = deployEnclave ? enclaveDeployment.outputs.enclaveResourceId : existingEnclaveResourceId

module workloadDeployment 'modules/aksClusterWorkload.bicep' = {
  name: 'deploy-workload-${uniqueString(workloadName)}'
  scope: subscription(targetSubscriptionId)
  params: {
    targetSubscriptionId: targetSubscriptionId
    enclaveResourceId: finalEnclaveResourceId
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
