
targetScope = 'subscription'

param storageAccountName string
@allowed ([
  'usgovvirginia'
  'usgovtexas'
])
param location string 
param resourceGroupName string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
}

module storageAccountModule './modules/storageAccount.bicep' = {
  name: 'storageAccountDeployment'
  scope: resourceGroup
  params: {
    storageAccountName: storageAccountName
    location: location
  }
}

output storageAccountId string = storageAccountModule.outputs.storageAccountId
