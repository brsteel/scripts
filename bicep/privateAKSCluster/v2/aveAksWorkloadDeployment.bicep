targetScope = 'subscription'

@description('Core deployment context (subscription, location, tags).')
param deploymentContext object

@allowed([true])
@description('Must be true. Confirms the AKS control-plane UAI service principal is granted Advanced maintenance-mode access for the enclave (direct principal assignment or via group membership).')
param aksControlPlaneIdentityInAdvancedMaintenanceMode bool

@allowed([true])
@description('Must be true. Confirms the AKS control-plane UAI service principal has enclave Contributor rights (direct principal assignment or via group membership in enclave role assignments).')
param aksControlPlaneIdentityHasEnclaveContributorRole bool

@description('Configuration for workload deployment (AKS workload, cluster, Key Vault, storage, and DNS linkage).')
param workloadConfiguration object

var tags = contains(deploymentContext, 'tags') ? deploymentContext.tags : {}
var location = contains(deploymentContext, 'location') && !empty(deploymentContext.location) ? deploymentContext.location : deployment().location
var targetSubscriptionId = contains(deploymentContext, 'subscriptionId') && !empty(deploymentContext.subscriptionId) ? deploymentContext.subscriptionId : subscription().subscriptionId

var enclaveResourceId = workloadConfiguration.enclaveResourceId
var workloadName = workloadConfiguration.name
var aksResourceGroupName = contains(workloadConfiguration, 'resourceGroupName') && !empty(workloadConfiguration.resourceGroupName)
  ? workloadConfiguration.resourceGroupName
  : toLower('${workloadName}-rg')
var aksResourceGroupLocation = contains(workloadConfiguration, 'location') && !empty(workloadConfiguration.location)
  ? workloadConfiguration.location
  : location
var communityManagedResourceGroupResourceId = workloadConfiguration.communityManagedResourceGroupResourceId
var privateDnsResourceGroupId = contains(workloadConfiguration, 'privateDnsResourceGroupId') ? workloadConfiguration.privateDnsResourceGroupId : ''
var managedResourceGroupName = contains(workloadConfiguration, 'managedResourceGroupName') ? workloadConfiguration.managedResourceGroupName : ''
var aksNetworkOverlay = contains(workloadConfiguration, 'aksNetworkOverlay') ? workloadConfiguration.aksNetworkOverlay : 'flatLegacy'
var aksDefinition = contains(workloadConfiguration, 'aksDefinition') ? workloadConfiguration.aksDefinition : {}
var keyVaultDefinition = contains(workloadConfiguration, 'keyVaultDefinition') ? workloadConfiguration.keyVaultDefinition : {}
var storageDefinition = contains(workloadConfiguration, 'storageDefinition') ? workloadConfiguration.storageDefinition : {}

module workloadDeployment '../privateAKSCluster/modules/aksClusterWorkload.bicep' = {
  name: 'deploy-workload-${uniqueString(workloadName)}'
  scope: subscription(targetSubscriptionId)
  params: {
    targetSubscriptionId: targetSubscriptionId
    enclaveResourceId: enclaveResourceId
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

output workloadResourceId string = workloadDeployment.outputs.workloadResourceId
output workloadResourceGroupId string = workloadDeployment.outputs.workloadResourceGroupId
output aksControlPlaneIdentityInAdvancedMaintenanceModeAcknowledged bool = aksControlPlaneIdentityInAdvancedMaintenanceMode
output aksControlPlaneIdentityHasEnclaveContributorRoleAcknowledged bool = aksControlPlaneIdentityHasEnclaveContributorRole
output prerequisiteAcknowledged bool = aksControlPlaneIdentityInAdvancedMaintenanceMode && aksControlPlaneIdentityHasEnclaveContributorRole
