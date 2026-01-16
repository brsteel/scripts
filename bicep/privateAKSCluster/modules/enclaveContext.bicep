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

// -- Dynamic Firewall Lookup --
var communityResourceId = contains(enclaveProperties, 'communityResourceId') && !empty(enclaveProperties.communityResourceId)
  ? string(enclaveProperties.communityResourceId)
  : ''

// Use the parameter to determine scope for Firewall lookup
var communityManagedRgName = split(communityManagedResourceGroupResourceId, '/')[4]
var communitySubscriptionId = split(communityManagedResourceGroupResourceId, '/')[2]

var communityName = !empty(communityResourceId) ? last(split(communityResourceId, '/')) : ''
// Assume firewall name follows convention. Location is tricky but usually same as enclosure.
// We can try to use resourceGroup().location if calling from this module scope, OR we assume community is same region.
var derivedLocation = resourceGroup().location
var firewallName = '${communityName}-fw-${derivedLocation}'

// We must use a nested module to perform the lookup because 'existing' resource needs a known scope at compile/start time.
// Since we have the RG name from parameter now, we can set the module scope!
module firewallLookup './firewallIpResolver.bicep' = if (!empty(communityManagedResourceGroupResourceId)) {
  name: 'firewall-lookup'
  scope: resourceGroup(communitySubscriptionId, communityManagedRgName)
  params: {
    firewallName: firewallName
  }
}

var derivedFirewallPrivateIp = !empty(communityManagedResourceGroupResourceId) ? firewallLookup.outputs.privateIp : ''

output managedResourceGroupName string = resolvedManagedResourceGroupName
output logAnalyticsResourceIds array = array(enclaveLogAnalyticsCollectionRaw)
output subnetConfigurations array = subnetConfigurations
output virtualNetworkResourceId string = fallbackVirtualNetworkResourceId
output firewallPrivateIp string = derivedFirewallPrivateIp
