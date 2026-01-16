param location string
param tags object = {}
param vnetName string
param subnetNames array
param firewallPrivateIp string

resource aksRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'rt-aks-egress'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource subnetUpdates 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = [for subnetName in subnetNames: {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: filter(vnet.properties.subnets, s => s.name == subnetName)[0].properties.addressPrefix
    routeTable: {
      id: aksRouteTable.id
    }
    delegations: filter(vnet.properties.subnets, s => s.name == subnetName)[0].properties.delegations
    networkSecurityGroup: filter(vnet.properties.subnets, s => s.name == subnetName)[0].properties.networkSecurityGroup
  }
}]

output routeTableId string = aksRouteTable.id
