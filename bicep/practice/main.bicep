param location string = 'usgovvirginia'
param storageAccountName string = 'bwssa${uniqueString(resourceGroup().id)}'
param appServiceAppName string = 'bwsapp${uniqueString(resourceGroup().id)}'

var appServicePlanName = '${appServiceAppName}-asp'

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

