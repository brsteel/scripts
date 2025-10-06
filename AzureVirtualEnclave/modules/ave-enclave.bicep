@description('The Azure region where resources will be deployed')
param location string

@description('Name of the virtual enclave')
param enclaveName string

@description('Community resource ID that this enclave belongs to')
param communityResourceId string

@description('Enclave configuration with nested workload configurations')
param enclaveConfig object

@description('Tags to apply to all resources')
param tags object

// Deploy Azure Virtual Enclave using native Microsoft.Mission resource
resource virtualEnclave 'Microsoft.Mission/virtualEnclaves@2024-12-01-preview' = {
  name: enclaveName
  location: location
  tags: tags
  identity: {
    type: 'None'
  }
  properties: {
    communityResourceId: communityResourceId
    bastionEnabled: enclaveConfig.bastionEnabled
    enclaveVirtualNetwork: {
      name: enclaveConfig.networkName
      networkSize: enclaveConfig.networkSize
      allowSubnetCommunication: enclaveConfig.allowSubnetCommunication
      connectToAzureServices: enclaveConfig.connectToAzureServices
      subnetConfigurations: [
        {
          name: 'workload-subnet'
          networkPrefixSize: 26  // /26 provides 64 IPs per subnet
        }
        {
          name: 'management-subnet' 
          networkPrefixSize: 28  // /28 provides 16 IPs for management
        }
      ]
    }
    enclaveDefaultSettings: {
      diagnosticDestination: 'Both'
    }
    enclaveRoleAssignments: []
    workloadRoleAssignments: []
    maintenanceModeConfiguration: {
      mode: 'Off'
    }
  }
}

// Deploy AVE Workloads within the enclave using nested configurations
module workloads 'ave-workload.bicep' = [for (workloadConfig, i) in enclaveConfig.workloadConfigs: {
  name: 'ave-workload-${i}'
  params: {
    location: location
    workloadName: workloadConfig.?name ?? '${enclaveName}-workload-${i}'
    parentEnclaveName: virtualEnclave.name
    workloadConfig: workloadConfig  // Pass individual workload config
    tags: union(tags, {
      WorkloadIndex: string(i)
    })
  }
}]

// Outputs
output enclaveName string = virtualEnclave.name
output enclaveResourceId string = virtualEnclave.id
output managedResourceGroupName string = virtualEnclave.properties.managedResourceGroupConfiguration.name
output deployedWorkloads array = [for (workloadConfig, i) in enclaveConfig.workloadConfigs: {
  name: workloadConfig.?name ?? '${enclaveName}-workload-${i}'
  resourceId: workloads[i].outputs.workloadResourceId
}]
