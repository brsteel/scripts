using 'solution.bicep'

// Minimal clean parameters file - test deployment
// 1 community, 2 enclaves, 1 workload per enclave

param baseName = 'contoso'

param numberOfCommunities = 1

// Enable governed service list defaults
param enableGovernedServiceList = true

// Optional: override default diagnostic destination ('Both' | 'CommunityOnly' | 'EnclaveOnly')
// param diagnosticDestinationDefault = 'Both'

param communityConfigs = [
  {
    addressSpace: '10.10.0.0/16'
    dnsServers: []
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkName: 'enc0-vnet'
        networkSize: '/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        diagnosticDestination: 'Both'
        maintenance: { mode: 'Off' }
        workloadConfigs: [
          {
            name: 'workload-a'
            resourceGroupCollection: ['rg-contoso-a']
          }
        ]
      }
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
          }
        ]
      }
    ]
  }
]

param tags = {
  Environment: 'Test'
  Project: 'AVE-Test'
  DeployedBy: 'Bicep'
  Purpose: 'Schema-Validation'
}

// Updated with real user object ID (brsteeltest)
param contributorPrincipals = ['abd8437b-107e-4c1b-9d65-6613f079ce61']
param communityReaders = []
param communityNetworkContributors = []
param communityMonitoringReaders = []
param communityMonitoringContributors = []
param communityLogAnalyticsReaders = []
param communityLogAnalyticsContributors = []
param communitySecurityReaders = []
param communitySecurityAdmins = []
param communityUserAccessAdministrators = []
