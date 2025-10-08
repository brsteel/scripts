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
  // Optional community-level maintenance object (example off)
  maintenance: {
    mode: 'Off'
  }
  // Optional community-level RBAC clear/override example (commented)
  // rbac: {
  //   readers: [] // would clear inherited communityReaders (if any were supplied above)
  // }
  enclaveConfigs: [
    // Enclave 0 with explicit RBAC override (adds a dedicated reader & clears monitoringContributors)
    {
      bastionEnabled: true
      networkName: 'enc0-vnet'
      networkSize: '/24'
      allowSubnetCommunication: true
      connectToAzureServices: true
      diagnosticDestination: 'Both'
      rbac: {
        readers: ['00000000-0000-0000-0000-000000000001']
        monitoringContributors: [] // clear (none wanted at enclave/workload scopes)
      }
      workloadConfigs: [
        {
          name: 'workload-a'
          resourceGroupCollection: ['rg-contoso-a']
          // Workload inherits enclave readers + cleared monitoringContributors
        }
      ]
    }
    // Enclave 1 demonstrating workload-level RBAC override + clearing contributors
    {
      bastionEnabled: false
      networkName: 'enc1-vnet'
      networkSize: '/24'
      allowSubnetCommunication: false
      connectToAzureServices: true
      diagnosticDestination: 'EnclaveOnly'
      workloadConfigs: [
        {
          name: 'workload-b'
          resourceGroupCollection: ['rg-contoso-b']
          rbac: {
            contributors: [] // clear inherited Contributor principals here
            logReaders: ['00000000-0000-0000-0000-0000000000AA']
          }
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
