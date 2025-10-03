using 'solution.bicep'

// Simple Development Environment Configuration
// ===========================================
// This creates a minimal AVE setup for development and learning purposes
// 1 Community -> 1 Enclave -> 2 Workloads

// Basic deployment parameters
// Short baseName to satisfy dynamic length assertion (see solution.bicep)
param baseName = 'ave1'
param location = 'USGov Virginia'

// Simple scale: 1 community, 1 enclave, 2 workloads  
param numberOfCommunities = 1
param numberOfEnclavesPerCommunity = 1  // Kept for backward compatibility
param numberOfWorkloadsPerEnclave = 2   // Kept for backward compatibility

// Single Development Community Configuration
param communityConfigs = [
  {
    // Community Network Configuration
    addressSpace: '10.0.0.0/16'        // Development network range
    dnsServers: []                      // Use Azure default DNS
    
    // approvalSettings omitted (RP validation issue)
    
    // Single Development Enclave
    enclaveConfigs: [
      {
        bastionEnabled: true                // Enable for admin access
        networkName: 'dev-vnet'
        networkSize: '/24'                  // Small network for dev (254 hosts)
        customCidrRange: '10.0.0.0/24'     // Specific CIDR range
        allowSubnetCommunication: true      // Allow communication between subnets
        connectToAzureServices: true        // Allow Azure service connectivity
        diagnosticDestination: 'EnclaveOnly'  // Basic diagnostics
        
        // Two Simple Workloads
        workloadConfigs: [
          {
            name: 'dev-app'
            resourceGroupCollection: ['rg-dev-app']
          }
          {
            name: 'dev-data'  
            resourceGroupCollection: ['rg-dev-data']
          }
        ]
      }
    ]
  }
]

// Resource tagging  
param tags = {
  Environment: 'Development'
  Project: 'Simple-AVE-Dev'
  DeployedBy: 'Bicep'
  Owner: 'Developer'
}
