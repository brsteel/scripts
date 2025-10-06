using 'solution.bicep'

// Single community, single enclave, single workload
param baseName = 'ave1test'
param location = 'usgovvirginia'
param numberOfCommunities = 1
param numberOfEnclavesPerCommunity = 1
param numberOfWorkloadsPerEnclave = 1
param deployEnclaves = true

// Compact naming enforced in template (baseName supplied at deploy time)
param communityConfigs = [
  {
    addressSpace: '10.10.0.0/16'
    dnsServers: []
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkName: 'web-tier-vnet'
        networkSize: '/24'
        customCidrRange: '10.10.0.0/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        diagnosticDestination: 'EnclaveOnly'
        // No workloads for this test deployment (focus on community + enclave success)
        workloadConfigs: []
      }
    ]
  }
]
