targetScope = 'resourceGroup'

@description('Name of the enclave that hosts this workload.')
param enclaveName string

@minLength(1)
@description('Name of the workload to create under the enclave.')
param workloadName string

@description('Azure region for the workload record.')
param location string

@description('Resource ID for the workload resource group that should be tracked by the workload.')
param workloadResourceGroupId string

@description('Tags applied to the workload resource.')
param tags object = {}

resource enclave 'Microsoft.Mission/virtualEnclaves@2025-05-01-preview' existing = {
  name: enclaveName
}

#disable-next-line BCP081
resource workload 'Microsoft.Mission/virtualEnclaves/workloads@2025-05-01-preview' = {
  parent: enclave
  name: workloadName
  location: location
  properties: {
    resourceGroupCollection: [
      workloadResourceGroupId
    ]
  }
  tags: tags
}

output workloadResourceId string = workload.id
