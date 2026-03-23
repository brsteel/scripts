targetScope = 'subscription'

@description('Core deployment context (subscription, location, tags).')
param deploymentContext object

@description('Configuration for enclave resources.')
param enclaveConfiguration object

@description('Configuration for community connectivity (AKS-required endpoint and connection).')
param connectivityConfiguration object = {}

@description('Configuration for AKS foundation resources created during enclave deployment.')
param aksFoundationConfiguration object = {}

var tags = contains(deploymentContext, 'tags') ? deploymentContext.tags : {}
var location = contains(deploymentContext, 'location') && !empty(deploymentContext.location) ? deploymentContext.location : deployment().location
var targetSubscriptionId = contains(deploymentContext, 'subscriptionId') && !empty(deploymentContext.subscriptionId) ? deploymentContext.subscriptionId : subscription().subscriptionId

var existingEnclaveResourceId = contains(enclaveConfiguration, 'existingResourceId') ? enclaveConfiguration.existingResourceId : ''
var deployEnclave = empty(existingEnclaveResourceId)

var aveResourceGroupName = enclaveConfiguration.resourceGroupName
var enclaveName = enclaveConfiguration.name
var communityResourceId = enclaveConfiguration.communityResourceId
var customCidrRange = contains(enclaveConfiguration, 'customCidrRange') ? enclaveConfiguration.customCidrRange : ''
var enableBastion = contains(enclaveConfiguration, 'enableBastion') ? enclaveConfiguration.enableBastion : true
var allowSubnetCommunication = contains(enclaveConfiguration, 'allowSubnetCommunication') ? enclaveConfiguration.allowSubnetCommunication : false
var diagnosticDestination = contains(enclaveConfiguration, 'diagnosticDestination') ? enclaveConfiguration.diagnosticDestination : 'Both'
var enclaveRoleAssignments = contains(enclaveConfiguration, 'enclaveRoleAssignments') ? enclaveConfiguration.enclaveRoleAssignments : []
var workloadRoleAssignments = contains(enclaveConfiguration, 'workloadRoleAssignments') ? enclaveConfiguration.workloadRoleAssignments : []
var maintenanceModePrincipals = contains(enclaveConfiguration, 'maintenanceModePrincipals') ? enclaveConfiguration.maintenanceModePrincipals : []
var maintenanceMode = contains(enclaveConfiguration, 'maintenanceMode') ? enclaveConfiguration.maintenanceMode : 'Advanced'
var allowedSubnetCommunications = contains(enclaveConfiguration, 'allowedSubnetCommunications') ? enclaveConfiguration.allowedSubnetCommunications : []
var subnetCommunicationRuleNamePrefix = contains(enclaveConfiguration, 'subnetCommunicationRuleNamePrefix')
  ? enclaveConfiguration.subnetCommunicationRuleNamePrefix
  : 'allow-subnet'
var subnetCommunicationPriorityStart = contains(enclaveConfiguration, 'subnetCommunicationPriorityStart')
  ? int(enclaveConfiguration.subnetCommunicationPriorityStart)
  : 3000
var identityConfig = contains(enclaveConfiguration, 'identity') ? enclaveConfiguration.identity : { type: 'SystemAssigned' }
var enclaveIdentityType = contains(identityConfig, 'type') ? identityConfig.type : 'SystemAssigned'
var enclaveUserAssignedIdentityResourceId = contains(identityConfig, 'userAssignedResourceId') ? identityConfig.userAssignedResourceId : ''
var enclaveUserAssignedIdentityName = contains(identityConfig, 'userAssignedName') ? identityConfig.userAssignedName : ''
var subnetDefinitions = contains(enclaveConfiguration, 'subnetDefinitions') ? enclaveConfiguration.subnetDefinitions : []

var enableAksRequiredConnectivity = contains(connectivityConfiguration, 'enableAksRequiredConnectivity') ? connectivityConfiguration.enableAksRequiredConnectivity : true
var aksRequiredSourceCidrs = contains(connectivityConfiguration, 'aksRequiredSourceCidrs') ? connectivityConfiguration.aksRequiredSourceCidrs : ''
var aksRequiredSourceSubnetNames = contains(connectivityConfiguration, 'aksRequiredSourceSubnetNames') ? connectivityConfiguration.aksRequiredSourceSubnetNames : []
var aksRequiredEndpointDefinition = contains(connectivityConfiguration, 'aksRequiredEndpointDefinition') ? connectivityConfiguration.aksRequiredEndpointDefinition : {}
var aksRequiredConnectionDefinition = contains(connectivityConfiguration, 'aksRequiredConnectionDefinition') ? connectivityConfiguration.aksRequiredConnectionDefinition : {}
var aksUserDefinedNetworkDefinitions = contains(connectivityConfiguration, 'aksUserDefinedNetworkDefinitions') ? connectivityConfiguration.aksUserDefinedNetworkDefinitions : []

var aksIdentityDefinition = contains(aksFoundationConfiguration, 'aksControlPlaneIdentity') ? aksFoundationConfiguration.aksControlPlaneIdentity : {}
var identityResourceGroupName = contains(aksIdentityDefinition, 'resourceGroupName') && !empty(aksIdentityDefinition.resourceGroupName) ? aksIdentityDefinition.resourceGroupName : aveResourceGroupName
var identityLocation = contains(aksIdentityDefinition, 'location') && !empty(aksIdentityDefinition.location) ? aksIdentityDefinition.location : location
var identityNameSeed = 'uai-${toLower(replace(replace(enclaveName, '_', '-'), '--', '-'))}-aks-cp'
var identityName = contains(aksIdentityDefinition, 'name') && !empty(aksIdentityDefinition.name)
  ? toLower(aksIdentityDefinition.name)
  : substring(identityNameSeed, 0, min(length(identityNameSeed), 128))

var egressRouteTableName = contains(aksFoundationConfiguration, 'egressRouteTableName') && !empty(aksFoundationConfiguration.egressRouteTableName)
  ? string(aksFoundationConfiguration.egressRouteTableName)
  : 'rt-aks-egress'
var egressSubnetNames = contains(aksFoundationConfiguration, 'egressSubnetNames') ? aksFoundationConfiguration.egressSubnetNames : []
var enablePrivateDnsZoneSetup = contains(aksFoundationConfiguration, 'enablePrivateDnsZoneSetup') ? bool(aksFoundationConfiguration.enablePrivateDnsZoneSetup) : true
var privateDnsResourceGroupResourceId = contains(aksFoundationConfiguration, 'privateDnsResourceGroupResourceId') ? string(aksFoundationConfiguration.privateDnsResourceGroupResourceId) : ''
var customPrivateDnsZoneNames = contains(aksFoundationConfiguration, 'privateDnsZoneNames') ? array(aksFoundationConfiguration.privateDnsZoneNames) : []
var workloadRbacDelegationConfig = contains(aksFoundationConfiguration, 'workloadRbacDelegation') ? aksFoundationConfiguration.workloadRbacDelegation : {}
var workloadRbacDelegationResourceGroupName = contains(workloadRbacDelegationConfig, 'resourceGroupName') ? string(workloadRbacDelegationConfig.resourceGroupName) : ''
var workloadRbacDelegationResourceGroupLocation = contains(workloadRbacDelegationConfig, 'resourceGroupLocation') && !empty(workloadRbacDelegationConfig.resourceGroupLocation)
  ? string(workloadRbacDelegationConfig.resourceGroupLocation)
  : location
var userAccessAdministratorRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '18d7d88d-d35e-4fb5-a5c3-7773c20a72d9')
var workloadRbacDelegationRoleDefinitionId = contains(workloadRbacDelegationConfig, 'roleDefinitionId') && !empty(workloadRbacDelegationConfig.roleDefinitionId)
  ? string(workloadRbacDelegationConfig.roleDefinitionId)
  : userAccessAdministratorRoleDefinitionId
var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var enclaveRoleDefinitionIds = [for assignment in enclaveRoleAssignments: assignment.roleDefinitionId]
var contributorIndex = indexOf(enclaveRoleDefinitionIds, contributorRoleDefinitionId)
var contributorPrincipals = contributorIndex == -1 ? [] : enclaveRoleAssignments[contributorIndex].principals
var workloadRbacDelegationPrincipals = contains(workloadRbacDelegationConfig, 'principals') && !empty(workloadRbacDelegationConfig.principals)
  ? workloadRbacDelegationConfig.principals
  : contributorPrincipals
var applyWorkloadRbacDelegation = !empty(workloadRbacDelegationResourceGroupName) && length(workloadRbacDelegationPrincipals) > 0
var createWorkloadRbacDelegationResourceGroup = applyWorkloadRbacDelegation && workloadRbacDelegationResourceGroupName != identityResourceGroupName

var storagePrivateDnsZoneName = format('privatelink.blob.{0}', environment().suffixes.storage)
var keyVaultDnsSuffixRaw = environment().suffixes.keyvaultDns
var keyVaultDnsSuffix = startsWith(keyVaultDnsSuffixRaw, '.')
  ? substring(keyVaultDnsSuffixRaw, 1, length(keyVaultDnsSuffixRaw) - 1)
  : keyVaultDnsSuffixRaw
var keyVaultPrivateDnsZoneName = format('privatelink.vaultcore.{0}', keyVaultDnsSuffix)
var isUsGov = environment().name == 'AzureUSGovernment'
var acrPrivateDnsZoneName = isUsGov ? 'privatelink.azurecr.us' : 'privatelink.azurecr.io'
var monitorPrivateDnsZoneName = isUsGov ? 'privatelink.monitor.azure.us' : 'privatelink.monitor.azure.com'
var omsPrivateDnsZoneName = isUsGov ? 'privatelink.oms.opinsights.azure.us' : 'privatelink.oms.opinsights.azure.com'
var odsPrivateDnsZoneName = isUsGov ? 'privatelink.ods.opinsights.azure.us' : 'privatelink.ods.opinsights.azure.com'
var agentSvcPrivateDnsZoneName = isUsGov ? 'privatelink.agentsvc.azure.us' : 'privatelink.agentsvc.azure-automation.net'
var defaultPrivateDnsZoneNames = [
  keyVaultPrivateDnsZoneName
  storagePrivateDnsZoneName
  acrPrivateDnsZoneName
  monitorPrivateDnsZoneName
  omsPrivateDnsZoneName
  odsPrivateDnsZoneName
  agentSvcPrivateDnsZoneName
]
var useExistingPrivateDnsZones = !empty(privateDnsResourceGroupResourceId) && length(customPrivateDnsZoneNames) > 0
var resolvedPrivateDnsZoneNames = useExistingPrivateDnsZones ? customPrivateDnsZoneNames : defaultPrivateDnsZoneNames
var privateDnsTargetSubscriptionId = useExistingPrivateDnsZones ? split(privateDnsResourceGroupResourceId, '/')[2] : targetSubscriptionId
var privateDnsTargetResourceGroupName = useExistingPrivateDnsZones ? split(privateDnsResourceGroupResourceId, '/')[4] : aveResourceGroupName
var shouldCreatePrivateDnsZones = !useExistingPrivateDnsZones

resource identityResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: identityResourceGroupName
  location: identityLocation
  tags: tags
}

module aksControlPlaneIdentity 'modules/aksControlPlaneIdentity.bicep' = {
  scope: resourceGroup(targetSubscriptionId, identityResourceGroupName)
  params: {
    identityName: identityName
    location: identityLocation
    tags: tags
  }
  dependsOn: [
    identityResourceGroup
  ]
}

module enclaveDeployment 'modules/aksEnclave.bicep' = if (deployEnclave) {
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
    maintenanceModePrincipals: maintenanceModePrincipals
    maintenanceMode: maintenanceMode
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

module privateDnsZoneManager 'modules/privateDnsZoneManager.bicep' = if (deployEnclave && enablePrivateDnsZoneSetup) {
  scope: resourceGroup(privateDnsTargetSubscriptionId, privateDnsTargetResourceGroupName)
  params: {
    dnsZoneNames: resolvedPrivateDnsZoneNames
    vnetResourceId: '/subscriptions/${targetSubscriptionId}/resourceGroups/${enclaveDeployment.outputs.managedResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${enclaveName}-vnet'
    createZones: shouldCreatePrivateDnsZones
    tags: tags
  }
}

var finalEnclaveResourceId = deployEnclave ? enclaveDeployment.outputs.enclaveResourceId : existingEnclaveResourceId

var runPostEnclaveManagedResources = deployEnclave && (length(egressSubnetNames) > 0 || length(allowedSubnetCommunications) > 0)

module postEnclaveManagedResources 'modules/postEnclaveManagedResources.bicep' = if (runPostEnclaveManagedResources) {
  scope: subscription(targetSubscriptionId)
  params: {
    targetSubscriptionId: targetSubscriptionId
    managedResourceGroupName: enclaveDeployment.outputs.managedResourceGroupName
    enclaveName: enclaveName
    location: location
    egressRouteTableName: egressRouteTableName
    egressSubnetNames: egressSubnetNames
    allowedSubnetCommunications: allowedSubnetCommunications
    ruleNamePrefix: subnetCommunicationRuleNamePrefix
    priorityStart: subnetCommunicationPriorityStart
    tags: tags
  }
}

resource workloadRbacDelegationResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = if (createWorkloadRbacDelegationResourceGroup) {
  name: workloadRbacDelegationResourceGroupName
  location: workloadRbacDelegationResourceGroupLocation
  tags: tags
}

module workloadRbacDelegationAssignments 'modules/workloadRbacDelegationRoleAssignments.bicep' = if (applyWorkloadRbacDelegation) {
  scope: resourceGroup(targetSubscriptionId, workloadRbacDelegationResourceGroupName)
  params: {
    targetSubscriptionId: targetSubscriptionId
    targetResourceGroupName: workloadRbacDelegationResourceGroupName
    roleDefinitionId: workloadRbacDelegationRoleDefinitionId
    principals: workloadRbacDelegationPrincipals
  }
  dependsOn: [
    workloadRbacDelegationResourceGroup
  ]
}

output enclaveResourceId string = finalEnclaveResourceId
output enclaveManagedResourceGroupName string = deployEnclave ? enclaveDeployment.outputs.managedResourceGroupName : ''
output aksControlPlaneIdentityResourceId string = aksControlPlaneIdentity.outputs.identityResourceId
output aksControlPlaneIdentityPrincipalId string = aksControlPlaneIdentity.outputs.identityPrincipalId
output aksControlPlaneIdentityClientId string = aksControlPlaneIdentity.outputs.identityClientId
output egressRouteTableId string = runPostEnclaveManagedResources ? postEnclaveManagedResources.outputs.routeTableId : ''
output subnetCommunicationRulesApplied int = runPostEnclaveManagedResources ? postEnclaveManagedResources.outputs.subnetCommunicationRulesApplied : 0
output privateDnsZoneResourceIds array = deployEnclave && enablePrivateDnsZoneSetup ? privateDnsZoneManager.outputs.dnsZoneResourceIds : []
output workloadRbacDelegationApplied bool = applyWorkloadRbacDelegation
output workloadRbacDelegationResourceGroupId string = applyWorkloadRbacDelegation ? '/subscriptions/${targetSubscriptionId}/resourceGroups/${workloadRbacDelegationResourceGroupName}' : ''
output workloadRbacDelegationRoleDefinitionId string = applyWorkloadRbacDelegation ? workloadRbacDelegationRoleDefinitionId : ''
