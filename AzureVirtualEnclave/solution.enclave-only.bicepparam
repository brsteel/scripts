using 'solution.bicep'

// Enclave-only diagnostic deployment: 1 community, 1 enclave, 0 workloads
param baseName = 'avd'
param location = 'USGov Virginia'
param numberOfCommunities = 1
param numberOfEnclavesPerCommunity = 1
param numberOfWorkloadsPerEnclave = 1 // legacy; workloads array will be empty so none deploy

param communityConfigs = [
  {
    addressSpace: '10.10.0.0/16'
    dnsServers: []
    enclaveConfigs: [
      {
        bastionEnabled: false
        networkName: 'diag-vnet'
        networkSize: '/24'
        customCidrRange: '10.10.0.0/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        diagnosticDestination: 'EnclaveOnly'
        workloadConfigs: [] // intentionally empty
      }
    ]
  }
]

param tags = {
  Environment: 'Diagnostics'
  Purpose: 'Enclave-VHub-Issue'
}
