targetScope = 'resourceGroup'

@description('Name of the AKS control-plane user-assigned managed identity.')
param identityName string

@description('Azure region for the managed identity.')
param location string

@description('Tags applied to the managed identity.')
param tags object = {}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: union(tags, {
    'mission-component': 'aks-control-plane-identity'
  })
}

output identityResourceId string = identity.id
output identityPrincipalId string = identity.properties.principalId
output identityClientId string = identity.properties.clientId
