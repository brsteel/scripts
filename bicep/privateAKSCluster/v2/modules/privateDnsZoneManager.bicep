param dnsZoneNames array
param vnetResourceId string
param createZones bool = true
param tags object = {}

resource dnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zone in dnsZoneNames: if (createZones) {
  name: zone
  location: 'global'
  tags: tags
}]

resource existingDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' existing = [for zone in dnsZoneNames: if (!createZones) {
  name: zone
}]

resource vnetLinksForCreatedZones 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in dnsZoneNames: if (createZones) {
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

resource vnetLinksForExistingZones 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zone, i) in dnsZoneNames: if (!createZones) {
  parent: existingDnsZones[i]
  name: 'link-${uniqueString(zone, vnetResourceId)}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetResourceId
    }
    registrationEnabled: false
  }
}]

var createdDnsZoneResourceIds = [for (zone, i) in dnsZoneNames: {
  name: zone
  id: dnsZones[i].id
}]

var existingDnsZoneResourceIds = [for (zone, i) in dnsZoneNames: {
  name: zone
  id: existingDnsZones[i].id
}]

output dnsZoneResourceIds array = createZones ? createdDnsZoneResourceIds : existingDnsZoneResourceIds
