param communityName string
param location string
param connectivityDefinitions array

resource parentCommunity 'Microsoft.Mission/communities@2024-12-01-preview' existing = {
  name: communityName
}

#disable-next-line BCP081
resource communityEndpoints 'Microsoft.Mission/communities/communityEndpoints@2024-12-01-preview' = [for (item, idx) in connectivityDefinitions: if (!contains(item.endpoint, 'existingResourceId') || empty(item.endpoint.existingResourceId)) {
  parent: parentCommunity
  name: item.endpoint.name
  location: location
  tags: item.endpoint.tags
  properties: item.endpoint.properties
}]

output endpointIds array = [for (item, idx) in connectivityDefinitions: (contains(item.endpoint, 'existingResourceId') && !empty(item.endpoint.existingResourceId)) ? item.endpoint.existingResourceId : communityEndpoints[idx].id]
