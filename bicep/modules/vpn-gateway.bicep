param name string
param location string = resourceGroup().location
param gatewayType string
param publicIpAddressSku string = 'Standard'

// public ip address names can be auto generated using the naming generator in MLZ  so this is temporary for testing purposes
param publicIpAddressNames array
param vpnType string
param vpnGatewayGeneration string
param sku string
param vnetName string
param localNetworkGatewayName string
param gatewayIpAddress string
param addressPrefixes array
param sharedKey string = ''
param keyVaultCertificateUri string = ''

// Existing Virtual Network and Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  name: vnetName
}

// Define a variable to store the list of existing subnets
var subnets = vnet.properties.subnets

// Define a variable to store the specified subnet
var gatewaySubnet = [for s in subnets: if (s.name == 'GatewaySubnet') s][0]

// Filter the list to find the specified subnet
var gatewaySubnetExists = !empty(gatewaySubnet)

// Output the subnet ID if it exists
output gatewaySubnetId string = gatewaySubnetExists ? gatewaySubnet.id : 'GatewaySubnet does not exist on the specified virtual network'

// Public IP Addresses
resource publicIpAddresses 'Microsoft.Network/publicIPAddresses@2023-02-01' = [for (name, index) in publicIpAddressNames: {
  name: name
  location: location
  sku: {
    name: publicIpAddressSku
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}]

var firstPublicIpAddressId = publicIpAddresses[0].id
var secondPublicIpAddressId = publicIpAddresses[1].id

// VPN Gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-02-01' = {
  name: name
  location: location
  properties: {
    gatewayType: gatewayType
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: firstPublicIpAddressId
          }
        }
      }
      {
        name: 'activeActive'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: secondPublicIpAddressId
          }
          subnet: {
            id: gatewaySubnetId
          }
        }
      }
    ]
    activeActive: true
    vpnType: vpnType
    vpnGatewayGeneration: vpnGatewayGeneration
    sku: {
      name: sku
      tier: sku
    }
  }
}

// Local Network Gateway
resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-02-01' = {
  name: localNetworkGatewayName
  location: location
  properties: {
    gatewayIpAddress: gatewayIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
}

// VPN Connection Module
module vpnConnectionModule 'vpn-connection.bicep' = {
  name: 'vpnConnectionModule'
  scope: resourceGroup()
  params: {
    vpnConnectionName: '${name}-to-${localNetworkGatewayName}'
    location: location
    vpnGatewayName: name
    vpnGatewayResourceGroupName: resourceGroup().name
    sharedKey: sharedKey
    keyVaultCertificateUri: keyVaultCertificateUri
    localNetworkGatewayName: localNetworkGatewayName
  }
}
