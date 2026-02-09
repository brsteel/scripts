targetScope = 'resourceGroup'

@description('Resource ID of the parent Mission enclave (used to derive VNet/subnet references).')
param enclaveResourceId string

@description('Name of the enclave-managed resource group. If provided, allows looking up the Firewall IP dynamicallly.')
param managedResourceGroupName string = ''

@description('Resource ID of the community managed resource group meant to host the firewall')
param communityManagedResourceGroupResourceId string

var enclaveDetails = reference(enclaveResourceId, '2025-05-01-preview', 'Full')
var enclavePropertiesRaw = enclaveDetails.properties
var enclaveProperties = empty(enclavePropertiesRaw) ? {} : enclavePropertiesRaw

var enclaveVirtualNetworkRaw = contains(enclaveProperties, 'enclaveVirtualNetwork') ? enclaveProperties.enclaveVirtualNetwork : {}
var enclaveVirtualNetwork = empty(enclaveVirtualNetworkRaw) ? {} : enclaveVirtualNetworkRaw
var subnetConfigurations = contains(enclaveVirtualNetwork, 'subnetConfigurations') && !empty(enclaveVirtualNetwork.subnetConfigurations)
  ? enclaveVirtualNetwork.subnetConfigurations
  : []

var resolvedManagedResourceGroupName = !empty(managedResourceGroupName)
  ? managedResourceGroupName
  : (contains(enclaveProperties, 'managedResourceGroupName') && !empty(enclaveProperties.managedResourceGroupName)
      ? string(enclaveProperties.managedResourceGroupName)
      : '')

var enclaveDefaultSettingsRaw = contains(enclaveProperties, 'enclaveDefaultSettings') ? enclaveProperties.enclaveDefaultSettings : {}
var enclaveDefaultSettings = empty(enclaveDefaultSettingsRaw) ? {} : enclaveDefaultSettingsRaw
var enclaveLogAnalyticsCollectionRaw = empty(enclaveDefaultSettings.logAnalyticsResourceIdCollection)
  ? []
  : enclaveDefaultSettings.logAnalyticsResourceIdCollection

var fallbackVirtualNetworkResourceId = contains(enclaveVirtualNetwork, 'virtualNetworkResourceId') && !empty(enclaveVirtualNetwork.virtualNetworkResourceId)
  ? string(enclaveVirtualNetwork.virtualNetworkResourceId)
  : ''

// -- Firewall Scope Resolution (Static Parsing) --
// We must parse the scope from the parameter string to avoid runtime reference() dependencies for module scope.
var communityResourceIdSegments = split(communityManagedResourceGroupResourceId, '/')

var communitySubscriptionId = length(communityResourceIdSegments) > 2 ? communityResourceIdSegments[2] : subscription().subscriptionId
var communityManagedRgName = length(communityResourceIdSegments) > 4 ? communityResourceIdSegments[4] : ''

// Infer Firewall Name from Community Managed RG Name Convention
// Convention: <CommunityName>-HostedResources-<Random>
// Firewall:   <CommunityName>-fw-<Location>
// We try to extract Community Name by taking the part before "-HostedResources"
var rgNameParts = split(communityManagedRgName, '-HostedResources')
var communityNameGuess = length(rgNameParts) > 0 ? rgNameParts[0] : 'avecommunity'

var derivedLocation = resourceGroup().location
var inferredFirewallName = '${communityNameGuess}-fw-${derivedLocation}'

// Lookup Module
// Only runs if we have a valid target RG.
module firewallLookup './firewallIpResolver.bicep' = if (!empty(communityManagedRgName)) {
  name: 'firewall-lookup'
  scope: resourceGroup(communitySubscriptionId, communityManagedRgName)
  params: {
    firewallName: inferredFirewallName
  }
}

var derivedFirewallPrivateIp = !empty(communityManagedRgName) ? firewallLookup.outputs.privateIp : ''

output managedResourceGroupName string = resolvedManagedResourceGroupName
output logAnalyticsResourceIds array = array(enclaveLogAnalyticsCollectionRaw)
output subnetConfigurations array = subnetConfigurations
output virtualNetworkResourceId string = fallbackVirtualNetworkResourceId
output firewallPrivateIp string = derivedFirewallPrivateIp
