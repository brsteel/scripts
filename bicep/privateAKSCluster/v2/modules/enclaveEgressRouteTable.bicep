targetScope = 'resourceGroup'

@description('Name of the enclave. Used to find the enclave VNet by convention.')
param enclaveName string

@description('Location for route table resources.')
param location string

@description('Route table name to create and associate to egress subnets.')
param routeTableName string = 'rt-aks-egress'

@description('List of enclave subnet names that should be associated to the egress route table.')
param subnetNames array

@description('Tags applied to the egress route table.')
param tags object = {}

resource enclaveVnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: '${enclaveName}-vnet'
}

resource egressRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: routeTableName
  location: location
  tags: union(tags, {
    'mission-component': 'aks-egress-route-table'
  })
  properties: {
    disableBgpRoutePropagation: false
    routes: []
  }
}

resource subnetUpdates 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = [for subnetName in subnetNames: {
  parent: enclaveVnet
  name: subnetName
  properties: {
    addressPrefix: filter(enclaveVnet.properties.subnets, s => s.name == subnetName)[0].properties.addressPrefix
    routeTable: {
      id: egressRouteTable.id
    }
    delegations: filter(enclaveVnet.properties.subnets, s => s.name == subnetName)[0].properties.delegations
    networkSecurityGroup: filter(enclaveVnet.properties.subnets, s => s.name == subnetName)[0].properties.networkSecurityGroup
  }
}]

output routeTableId string = egressRouteTable.id
