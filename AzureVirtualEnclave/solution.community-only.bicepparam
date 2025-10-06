using './solution.bicep'

// Test deployment with just community, no enclaves to isolate the issue
// This will help us determine if the problem is with communities or enclaves

param baseName = 'ave-comm-only'
param location = 'USGov Virginia' 
param numberOfCommunities = 1

param communityConfigs = [
  {
    addressSpace: '10.0.0.0/16'
    dnsServers: []
    // Empty enclaves array - deploy just the community
    enclaveConfigs: []
  }
]

// Basic development tags
param tags = {
  Environment: 'Development'
  Purpose: 'AVE-Community-Only-Test'
  Owner: 'DevTeam'
}
