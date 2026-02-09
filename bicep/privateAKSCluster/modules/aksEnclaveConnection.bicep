param enclaveName string
param enclaveResourceId string
param communityResourceId string
param customCidrRange string
param tags object = {}
param enableAksRequiredConnectivity bool = true
param aksRequiredSourceCidrs string = ''
param aksRequiredSourceSubnetNames array = []
param aksRequiredEndpointDefinition object = {}
param aksRequiredConnectionDefinition object = {}
param aksUserDefinedNetworkDefinitions array = []
param subnetConfigurations array = []

var normalizedEnclaveNameSegment = toLower(replace(replace(enclaveName, '_', '-'), '--', '-'))
var communityResourceIdSegments = split(communityResourceId, '/')
var communityNameSegment = length(communityResourceIdSegments) > 8 ? communityResourceIdSegments[8] : normalizedEnclaveNameSegment
var communitySubscriptionId = length(communityResourceIdSegments) > 2 ? communityResourceIdSegments[2] : subscription().subscriptionId
var communityResourceGroupName = length(communityResourceIdSegments) > 4 ? communityResourceIdSegments[4] : resourceGroup().name

// parentCommunity resource removed as it is now handled inside communitySideResources.bicep
// which is scoped to the correct Resource Group.

var namePrefixLength = min(length(normalizedEnclaveNameSegment), 16)
var normalizedEndpointPrefix = namePrefixLength > 0 ? substring(normalizedEnclaveNameSegment, 0, namePrefixLength) : 'enclave'
var uniqueNameToken = substring(uniqueString(resourceGroup().id, enclaveName, 'aks-egress'), 0, 6)

var proposedAksRequiredEndpointName = toLower('ce-${normalizedEndpointPrefix}-${uniqueNameToken}')
var proposedAksRequiredConnectionName = toLower('ec-${normalizedEndpointPrefix}-${uniqueNameToken}')
var aksRequiredEndpointName = substring(proposedAksRequiredEndpointName, 0, min(length(proposedAksRequiredEndpointName), 30))
var aksRequiredConnectionName = substring(proposedAksRequiredConnectionName, 0, min(length(proposedAksRequiredConnectionName), 30))

var aksRequiredEndpointTags = union(tags, {
  'mission-component': 'aks-egress'
})

var blobSuffix = environment().suffixes.storage
var cloudMapping = {
  AzureCloud: {
    #disable-next-line no-hardcoded-env-urls
    aks: 'azmk8s.io'
    #disable-next-line no-hardcoded-env-urls
    management: 'management.azure.com'
    #disable-next-line no-hardcoded-env-urls
    login: 'login.microsoftonline.com'
  }
  AzureUSGovernment: {
    #disable-next-line no-hardcoded-env-urls
    aks: 'azmk8s.usgovcloudapi.net'
    #disable-next-line no-hardcoded-env-urls
    management: 'management.usgovcloudapi.net'
    #disable-next-line no-hardcoded-env-urls
    login: 'login.microsoftonline.us'
  }
}
var currentCloud = contains(cloudMapping, environment().name) ? cloudMapping[environment().name] : cloudMapping.AzureCloud

var aksRequiredEndpointRules = [
  {
    name: 'aks-control-plane'
    destinationType: 'FQDN'
    destination: '*.${currentCloud.aks},${currentCloud.management}'
    protocols: [
      'HTTPS'
    ]
    port: '443'
  }
  {
    name: 'aks-registry'
    destinationType: 'FQDN'
    destination: 'mcr.microsoft.com,*.data.mcr.microsoft.com,*.cdn.mscr.io,*.azurecr.io,*.blob.${blobSuffix}'
    protocols: [
      'HTTPS'
    ]
    port: '443'
  }
  {
    name: 'aks-auth'
    destinationType: 'FQDN'
    destination: currentCloud.login
    protocols: [
      'HTTPS'
    ]
    port: '443'
  }
  {
    name: 'aks-packages'
    destinationType: 'FQDN'
    #disable-next-line no-hardcoded-env-urls
    destination: 'packages.microsoft.com,acs-mirror.azureedge.net,security.ubuntu.com,snapcraft.io,api.snapcraft.io'
    protocols: [
      'HTTPS'
    ]
    port: '443'
  }
  {
    name: 'aks-packages-http'
    destinationType: 'FQDN'
    #disable-next-line no-hardcoded-env-urls
    destination: 'packages.microsoft.com,acs-mirror.azureedge.net,security.ubuntu.com,snapcraft.io,api.snapcraft.io'
    protocols: [
      'HTTP'
    ]
    port: '80'
  }
]

var resolvedSourceCidrsFromNames = [for name in aksRequiredSourceSubnetNames: filter(subnetConfigurations, (s) => s.subnetName == name)[0].addressPrefix]

var aksConnectivitySourceCidr = !empty(aksRequiredSourceSubnetNames) 
  ? join(resolvedSourceCidrsFromNames, ',') 
  : (empty(aksRequiredSourceCidrs) ? customCidrRange : aksRequiredSourceCidrs)

var aksRequiredEndpointDefinitionOverrides = empty(aksRequiredEndpointDefinition) ? {} : aksRequiredEndpointDefinition
var resolvedAksRequiredEndpointName = contains(aksRequiredEndpointDefinitionOverrides, 'name') && !empty(aksRequiredEndpointDefinitionOverrides.name) ? string(aksRequiredEndpointDefinitionOverrides.name) : aksRequiredEndpointName
var customAksRequiredEndpointTags = contains(aksRequiredEndpointDefinitionOverrides, 'tags') && !empty(aksRequiredEndpointDefinitionOverrides.tags) ? aksRequiredEndpointDefinitionOverrides.tags : {}
var resolvedAksRequiredEndpointTags = union(aksRequiredEndpointTags, customAksRequiredEndpointTags)
var defaultAksRequiredEndpointProperties = {
  ruleCollection: aksRequiredEndpointRules
}
var customAksRequiredEndpointProperties = contains(aksRequiredEndpointDefinitionOverrides, 'properties') && !empty(aksRequiredEndpointDefinitionOverrides.properties) ? aksRequiredEndpointDefinitionOverrides.properties : {}
var resolvedAksRequiredEndpointProperties = union(defaultAksRequiredEndpointProperties, customAksRequiredEndpointProperties)

var aksRequiredConnectionDefinitionOverrides = empty(aksRequiredConnectionDefinition) ? {} : aksRequiredConnectionDefinition
var resolvedAksRequiredConnectionName = contains(aksRequiredConnectionDefinitionOverrides, 'name') && !empty(aksRequiredConnectionDefinitionOverrides.name) ? string(aksRequiredConnectionDefinitionOverrides.name) : aksRequiredConnectionName
var customAksRequiredConnectionTags = contains(aksRequiredConnectionDefinitionOverrides, 'tags') && !empty(aksRequiredConnectionDefinitionOverrides.tags) ? aksRequiredConnectionDefinitionOverrides.tags : {}
var resolvedAksRequiredConnectionTags = union(aksRequiredEndpointTags, customAksRequiredConnectionTags)
var defaultDefinition = {
  endpoint: {
    name: resolvedAksRequiredEndpointName
    tags: resolvedAksRequiredEndpointTags
    properties: resolvedAksRequiredEndpointProperties
  }
  connection: {
    name: resolvedAksRequiredConnectionName
    tags: resolvedAksRequiredConnectionTags
    sourceCidr: aksConnectivitySourceCidr
    properties: {
      communityResourceId: communityResourceId
      sourceResourceId: enclaveResourceId
    }
  }
}

var resolvedUserDefinedDefinitions = [for (item, idx) in aksUserDefinedNetworkDefinitions: {
  endpoint: {
    existingResourceId: contains(item, 'endpoint') && contains(item.endpoint, 'existingResourceId') ? item.endpoint.existingResourceId : ''
    name: contains(item, 'endpoint') && contains(item.endpoint, 'name') && !empty(item.endpoint.name)
      ? string(item.endpoint.name)
      : format('ce-{0}-{1}', normalizedEndpointPrefix, idx)
    tags: union(aksRequiredEndpointTags, contains(item, 'endpoint') && contains(item.endpoint, 'tags') && !empty(item.endpoint.tags) ? item.endpoint.tags : {})
    properties: union({
      ruleCollection: aksRequiredEndpointRules
    }, contains(item, 'endpoint') && contains(item.endpoint, 'properties') && !empty(item.endpoint.properties) ? item.endpoint.properties : {})
  }
  connection: {
    name: contains(item, 'connection') && contains(item.connection, 'name') && !empty(item.connection.name)
      ? string(item.connection.name)
      : format('ec-{0}-{1}', normalizedEndpointPrefix, idx)
    tags: union(aksRequiredEndpointTags, contains(item, 'connection') && contains(item.connection, 'tags') && !empty(item.connection.tags) ? item.connection.tags : {})
    sourceCidr: contains(item, 'connection') && contains(item.connection, 'subnetNames') && !empty(item.connection.subnetNames) 
      ? join(map(item.connection.subnetNames, name => filter(subnetConfigurations, (s) => s.subnetName == name)[0].addressPrefix), ',') 
      : aksConnectivitySourceCidr
    properties: union({
      communityResourceId: communityResourceId
      sourceResourceId: enclaveResourceId
    }, contains(item, 'connection') && contains(item.connection, 'properties') && !empty(item.connection.properties) ? item.connection.properties : {})
  }
}]

var allConnectivityDefinitions = enableAksRequiredConnectivity ? union([defaultDefinition], resolvedUserDefinedDefinitions) : resolvedUserDefinedDefinitions

module communityEndpointsDeployment 'communitySideResources.bicep' = {
  name: 'deploy-community-endpoints-${uniqueNameToken}'
  scope: resourceGroup(communitySubscriptionId, communityResourceGroupName)
  params: {
    communityName: communityNameSegment
    location: resourceGroup().location
    connectivityDefinitions: allConnectivityDefinitions
  }
}

#disable-next-line BCP081
resource communityConnections 'Microsoft.Mission/enclaveConnections@2024-12-01-preview' = [for (item, idx) in allConnectivityDefinitions: {
  name: item.connection.name
  location: resourceGroup().location
  tags: item.connection.tags
  properties: {
    communityResourceId: communityResourceId
    sourceResourceId: enclaveResourceId
    sourceCidr: item.connection.sourceCidr
    destinationEndpointId: communityEndpointsDeployment.outputs.endpointIds[idx]
  }
}]
