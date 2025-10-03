using 'solution.bicep'

// MINIMAL Development Environment  
// ===============================
// The simplest possible AVE deployment for learning and testing
// 1 Community -> 1 Enclave -> 1 Workload

param baseName = 'ave-com'
param location = 'USGov Virginia' 
param numberOfCommunities = 1

param communityConfigs = [
  {
    addressSpace: '10.0.0.0/16'
    dnsServers: []
    
    // approvalSettings omitted (RP validation issue)
    
    // Single minimal enclave
    enclaveConfigs: [
      {
        bastionEnabled: true
        networkName: 'minimal-vnet'
        networkSize: '/24'
        customCidrRange: '10.0.0.0/24'
        allowSubnetCommunication: true
        connectToAzureServices: true
        
        // Single workload
        workloadConfigs: [
          {
            name: 'minimal-workload'
            resourceGroupCollection: []  // Empty - will be populated when resources are deployed
          }
        ]
      }
    ]
  }
]

param tags = {
  Environment: 'Minimal-Dev'
  Purpose: 'Learning'
}