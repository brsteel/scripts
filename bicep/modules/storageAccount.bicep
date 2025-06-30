targetScope = 'resourceGroup'

param storageAccountName string
param location string
param skuName string = 'Standard_LRS'
param kind string = 'StorageV2'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: kind
  properties: {}
}

output storageAccountId string = storageAccount.id
