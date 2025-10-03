@description('The Azure region where resources will be deployed')
param location string

@description('Name of the workload')
param workloadName string

@description('Parent Virtual Enclave name')
param parentEnclaveName string

@description('Tags to apply to all resources')
param tags object

@description('Workload configuration settings')
param workloadConfig object

// Reference the parent virtual enclave
resource parentEnclave 'Microsoft.Mission/virtualEnclaves@2024-12-01-preview' existing = {
  name: parentEnclaveName
}

// Deploy AVE Workload as a child resource of the virtual enclave
// Workloads are container objects that will contain resources when deployed
resource workload 'Microsoft.Mission/virtualEnclaves/workloads@2024-12-01-preview' = {
  name: workloadName
  parent: parentEnclave
  location: location
  tags: tags
  properties: {
    resourceGroupCollection: workloadConfig.?resourceGroupCollection ?? []
  }
}

// Outputs
output workloadName string = workload.name
output workloadResourceId string = workload.id
output provisioningState string = workload.properties.provisioningState
output resourceGroupCollection array = workload.properties.resourceGroupCollection