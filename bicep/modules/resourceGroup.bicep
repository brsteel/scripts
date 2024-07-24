targetScope = 'subscription'
param resourceGroupName string
param resourceGroupLocation string

resource exrResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

output resourceGroupId string = exrResourceGroup.id
output resourceGroupName string = exrResourceGroup.name
output resourceGroupLocation string = exrResourceGroup.location
