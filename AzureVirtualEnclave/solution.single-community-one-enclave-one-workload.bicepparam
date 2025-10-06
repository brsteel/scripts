using 'solution.bicep'

// Single community, single enclave, single workload (minimal RG collection to avoid BadRequest)
param baseName = 'ave1work'
param location = 'usgovvirginia'
param numberOfCommunities = 1
param numberOfEnclavesPerCommunity = 1
param numberOfWorkloadsPerEnclave = 1
param deployEnclaves = true

// NOTE: resourceGroupCollection must be an array; RP previously rejected short names that are not full ARM IDs.
// For now, we provide an empty array to let workload container provision. Adjust later once expected format is clarified.
param communityConfigs = [
  {
    addressSpace: '10.20.0.0/16'
    dnsServers: []
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkName: 'core-vnet'
        networkSize: '/24'
        customCidrRange: '10.20.0.0/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        diagnosticDestination: 'EnclaveOnly'
        workloadConfigs: [
          {
            name: 'app-1'
            // Provide empty list until RG collection spec is confirmed for preview.
            resourceGroupCollection: []
          }
        ]
      }
    ]
  }
]