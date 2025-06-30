@description('Resource group of the existing VNet.')
param vnetResourceGroup string

@description('Name of the existing VNet.')
param vnetName string

@description('Location for the Application Gateway.')
param location string

@description('Name for the Application Gateway.')
param appGatewayName string

@description('Prefix for the new subnet name.')
param subnetNamePrefix string = 'appgw'

@description('Frontend configuration for the Application Gateway.')
param frontendIPConfigs array

@description('Frontend ports for the Application Gateway.')
param frontendPorts array

@description('Backend pools for the Application Gateway.')
param backendAddressPools array

@description('Backend HTTP settings for the Application Gateway.')
param backendHttpSettingsCollection array

@description('Routing rules for the Application Gateway.')
param requestRoutingRules array

// Reference the existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

// Get all existing subnets' address prefixes
var existingPrefixes = [for s in vnet.properties.subnets: s.properties.addressPrefix]

// Use the recommended prefix length for Application Gateway subnet (/27)
var subnetPrefixLength = 27

// Parse VNet base and prefix length
var vnetAddressPrefix = vnet.properties.addressSpace.addressPrefixes[0]
var vnetPrefixBase = split(vnetAddressPrefix, '/')[0]
var vnetPrefixLength = int(split(vnetAddressPrefix, '/')[1])

// Only works for /16 or /24 VNet prefixes
var baseOctets = split(vnetPrefixBase, '.')
var subnetCount = pow(2, subnetPrefixLength - vnetPrefixLength)

// Generate all possible /27 subnets in the VNet
var allPossibleSubnets = [
  for i in range(0, subnetCount - 1): 
    // For /16 VNet, generate 10.0.{i}.0/27, 10.0.{i}.32/27, ..., 10.0.{i}.224/27 for each /24, then increment third octet
    // For /24 VNet, generate 10.0.0.{i * 32}/27
    vnetPrefixLength == 16
      ? '${baseOctets[0]}.${baseOctets[1]}.${int(i / 8)}.${(i % 8) * 32}/${subnetPrefixLength}'
      : '${baseOctets[0]}.${baseOctets[1]}.${baseOctets[2]}.${i * 32}/${subnetPrefixLength}'
]

// Filter out subnets that overlap with existing subnets
var availableSubnets = [
  for subnet in allPossibleSubnets:
    (!contains(existingPrefixes, subnet)) ? subnet : null
]

// Pick the first available subnet
var newSubnetPrefix = first([for s in availableSubnets: s if s != null])

var subnetName = '${subnetNamePrefix}-subnet'

// Create the subnet for Application Gateway
resource appGwSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' = {
  name: '${vnet.name}/${subnetName}'
  properties: {
    addressPrefix: newSubnetPrefix
  }
  parent: vnet
}

// Create the Application Gateway
resource appGateway 'Microsoft.Network/applicationGateways@2022-09-01' = {
  name: appGatewayName
  location: location
  sku: {
    name: 'WAF_v2'
    tier: 'WAF_v2'
    capacity: 2
  }
  properties: {
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGwSubnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: frontendIPConfigs
    frontendPorts: frontendPorts
    backendAddressPools: backendAddressPools
    backendHttpSettingsCollection: backendHttpSettingsCollection
    requestRoutingRules: requestRoutingRules
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
    }
  }
}
