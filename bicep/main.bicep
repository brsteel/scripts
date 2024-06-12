param resourceGroupId string
param location string

targetScope = 'subscription'

resource deleteResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  resourceId: resourceGroupId
  location: location
}
