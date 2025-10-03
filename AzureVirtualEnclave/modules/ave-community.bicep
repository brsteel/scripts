@description('The Azure region where resources will be deployed')
param location string

@description('Name of the AVE community')
param communityName string

@description('Community configuration with nested enclave and workload configurations')
param communityConfig object

@description('Tags to apply to all resources')
param tags object


@description('When false, enclaves (and workloads) are skipped for phased deployments')
param deployEnclaves bool = true

// Deploy Azure Virtual Enclave Community using native Microsoft.Mission resource
resource aveCommnity 'Microsoft.Mission/communities@2024-12-01-preview' = {
  name: communityName
  location: location
  tags: tags
  identity: {
    type: 'None'
  }
  properties: {
    addressSpace: communityConfig.addressSpace
    dnsServers: communityConfig.dnsServers
    // approvalSettings intentionally omitted (US Gov RP validation issue)
    communityRoleAssignments: []
    governedServiceList: [
      {
        id: 'Storage'
        option: 'Allow'
        enforcement: 'Enabled'
        auditOnly: false
      }
      {
        id: 'KeyVault'
        option: 'Allow'
        enforcement: 'Enabled'
        auditOnly: false
      }
      {
        id: 'Monitoring'
        option: 'Allow'
        enforcement: 'Enabled'
        auditOnly: false
      }
      {
        id: 'AKS'
        option: 'Allow'
        enforcement: 'Enabled'
        auditOnly: false
      }
    ]
    maintenanceModeConfiguration: {
      mode: 'Off'
    }
  }
}

// Deploy Virtual Enclaves within the community using nested configurations
module virtualEnclaves 'ave-enclave.bicep' = [for (enclaveConfig, i) in (deployEnclaves ? communityConfig.enclaveConfigs : []): {
  name: 'ave-enclave-${i}'
  params: {
    location: location
  enclaveName: '${communityName}e${i}'
    communityResourceId: aveCommnity.id
    enclaveConfig: enclaveConfig
    tags: union(tags, { EnclaveIndex: string(i) })
  }
}]

// Outputs
output communityName string = aveCommnity.name
output communityResourceId string = aveCommnity.id
output managedResourceGroupName string = aveCommnity.properties.managedResourceGroupConfiguration.name
output deployedEnclaves array = [for (enclaveConfig, i) in (deployEnclaves ? communityConfig.enclaveConfigs : []): {
  name: '${communityName}e${i}'
  resourceId: deployEnclaves ? virtualEnclaves[i].outputs.enclaveResourceId : ''
}]