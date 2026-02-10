param location string
param tags object = {}
param vnetName string
param subnetNames array
param routeTableId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource subnetUpdates 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = [for subnetName in subnetNames: {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: filter(vnet.properties.subnets, s => s.name == subnetName)[0].properties.addressPrefix
    routeTable: {
      id: routeTableId
    }
    delegations: filter(vnet.properties.subnets, s => s.name == subnetName)[0].properties.delegations
    networkSecurityGroup: filter(vnet.properties.subnets, s => s.name == subnetName)[0].properties.networkSecurityGroup
  }
}]
