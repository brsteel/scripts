using 'solution.bicep'

// Updated single-community parameter file with enclave + workload RBAC override examples

param baseName = 'contoso'
param enableGovernedServiceList = true
param diagnosticDestinationDefault = 'Both'

// Community-level RBAC buckets (inheritance source)
param contributorPrincipals = ['abd8437b-107e-4c1b-9d65-6613f079ce61'] // example objectId
param communityReaders = []
param communityNetworkContributors = []
param communityMonitoringReaders = []
param communityMonitoringContributors = []
param communityLogAnalyticsReaders = []
param communityLogAnalyticsContributors = []
param communitySecurityReaders = []
param communitySecurityAdmins = []
param communityUserAccessAdministrators = []

// Single community configuration
param communityConfig = {
  addressSpace: '10.10.0.0/16'
  dnsServers: []
  // Community now in Advanced maintenance with required principals
  maintenance: {
    mode: 'Advanced'
    principals: [
      'abd8437b-107e-4c1b-9d65-6613f079ce61' // PIM-enabled group (example)
    ]
    principalType: 'User'
  }
  enclaveConfigs: [
    // Enclave 0 remains Off (inherits none; separate test of mix)
    {
      bastionEnabled: true
      networkName: 'enc0-vnet'
      networkSize: '/24'
      allowSubnetCommunication: true
      connectToAzureServices: true
      diagnosticDestination: 'Both'
      workloadConfigs: [
        {
          name: 'workload-a'
          resourceGroupCollection: ['rg-contoso-a']
        }
      ]
    }
    // Enclave 1 explicitly sets Advanced with its own principals
    {
      bastionEnabled: false
      networkName: 'enc1-vnet'
      networkSize: '/24'
      allowSubnetCommunication: false
      connectToAzureServices: true
      diagnosticDestination: 'EnclaveOnly'
      maintenance: {
        mode: 'Advanced'
        principals: [ '00000000-0000-0000-0000-0000000000BB' ]
        principalType: 'User'
      }
      workloadConfigs: [
        {
          name: 'workload-b'
          resourceGroupCollection: ['rg-contoso-b']
        }
      ]
    }
  ]
}

param tags = {
  Environment: 'Test'
  Project: 'AVE-Test'
  DeployedBy: 'Bicep'
  Purpose: 'Schema-Validation'
}
