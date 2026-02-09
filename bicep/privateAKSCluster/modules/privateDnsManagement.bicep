param dnsZoneNames array
param vnetResourceId string
param tags object = {}

resource dnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zone in dnsZoneNames: {
  name: zone
  location: 'global'
  tags: tags
}]

resource vnetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in dnsZoneNames: {
  parent: dnsZones[i]
  name: 'link-${uniqueString(zone, vnetResourceId)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetResourceId
    }
    registrationEnabled: false
  }
}]

output dnsZoneResourceIds array = [for (zone, i) in dnsZoneNames: {
  name: zone
  id: dnsZones[i].id
}]
