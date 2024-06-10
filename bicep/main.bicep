resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: 'toylaunchbrookesteele'
  location: 'eastus'
  sku: {
    name: 'Standard_LRS'
  }
  kind:'StorageV2'
  properties: {
    accessTier: 'Hot' 
  }
}
