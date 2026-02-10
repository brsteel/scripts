using './aveAksDeployment.bicep'

// --------------------------------------------------------------------------------
// DEPLOYMENT CONTEXT
// --------------------------------------------------------------------------------
param deploymentContext = {
  // Subscription ID where the resources will be deployed. Defaults to current subscription if empty.
  subscriptionId: '00000000-0000-0000-0000-000000000000'
  
  // Azure Region for the deployment. Defaults to deployment location if empty.
  location: 'eastus'
  
  // Tags to apply to all resources.
  tags: {
    Environment: 'Development'
    Project: 'PrivateAKS'
  }
}

// --------------------------------------------------------------------------------
// ENCLAVE CONFIGURATION
// --------------------------------------------------------------------------------
param enclaveConfiguration = {
  // If provided, the existing enclave resource ID will be used, and the enclave creation (modules/aksEnclave.bicep) will be skipped.
  // existingResourceId: '/subscriptions/.../resourceGroups/.../providers/Microsoft.Mission/virtualEnclaves/my-enclave'

  // Name of the resource group to create for the Enclave.
  resourceGroupName: 'my-enclave-rg'
  
  // Name of the enclave (Microsoft.Mission/virtualEnclaves resource name).
  name: 'my-enclave'
  
  // Resource ID of the parent community to attach this enclave to.
  communityResourceId: '<INSERT_COMMUNITY_RESOURCE_ID>'
  
  // Explicit CIDR to request for the enclave base VNet.
  customCidrRange: '10.0.1.0/24'
  
  // Enable Bastion access to enclave.
  enableBastion: false
  
  // Allow broad subnet-to-subnet communication.
  allowSubnetCommunication: false
  
  // Diagnostic destination: CommunityOnly | EnclaveOnly | Both | Unspecified.
  diagnosticDestination: 'EnclaveOnly'
  
  // Identity configuration for the enclave resource.
  identity: {
    type: 'SystemAssigned' // or 'UserAssigned'
    // userAssignedResourceId: '' // Required if type is UserAssigned
    // userAssignedName: '' // Optional override for auto-created identity
  }
  
  // Custom subnet definitions (optional).
  subnetDefinitions: []
  
  // Role assignments for the enclave scope (optional).
  roleAssignments: []
}

// --------------------------------------------------------------------------------
// CONNECTIVITY CONFIGURATION
// --------------------------------------------------------------------------------
param connectivityConfiguration = {
  // Automatically create the AVE community endpoint and enclave connection required for AKS outbound connectivity.
  enableAksRequiredConnectivity: true
  
  // Comma-separated list of CIDR ranges to use for the AKS community connection source.
  aksRequiredSourceCidrs: ''
  
  // Optional list of subnet names to dynamically resolve to CIDR ranges.
  aksRequiredSourceSubnetNames: []
  
  // Optional override for the generated AKS community endpoint definition.
  // To use an existing endpoint, provide 'existingResourceId': '/subscriptions/...'
  // To force a specific name: 'aksCommunityEndpointName': 'my-endpoint-name'
  aksRequiredEndpointDefinition: {}
  
  // Optional override for the generated AKS community connection definition.
  // To force a specific name: 'aksEnclaveConnectionName': 'my-connection-name'
  aksRequiredConnectionDefinition: {}
  
  // Additional community endpoint + connection objects to create.
  aksUserDefinedNetworkDefinitions: []
}

// --------------------------------------------------------------------------------
// WORKLOAD CONFIGURATION
// --------------------------------------------------------------------------------
param workloadConfiguration = {
  // Name of the workload to create under the enclave.
  name: 'my-aks-workload'
  
  // Name of the AKS workload resource group.
  resourceGroupName: 'my-aks-workload-rg'
  
  // Azure region for the AKS workload resource group.
  location: 'eastus'
  
  // AKS network overlay selection: 'flatLegacy', 'azureCniPodSubnet', 'azureCniOverlay'.
  aksNetworkOverlay: 'flatLegacy'
  
  // Resource ID of the community managed resource group meant to host the firewall (Required).
  communityManagedResourceGroupResourceId: '<INSERT_COMMUNITY_MANAGED_RG_ID>'
  
  // Name of the enclave-managed resource group (informational/override).
  managedResourceGroupName: 'my-enclave-managed-rg'
  
  // Resource ID of the Resource Group where Private DNS Zones should be created/linked (Centralized DNS).
  privateDnsResourceGroupId: ''
  
  // AKS configuration overrides (cluster, networking, diagnostics, identity).
  aksDefinition: {
    // Example:
    // nodePools: [
    //   {
    //     name: 'agentpool'
    //     vmSize: 'Standard_D4s_v5'
    //     count: 3
    //   }
    // ]
  }
  
  // Key Vault configuration overrides.
  keyVaultDefinition: {}
  
  // Storage account configuration overrides.
  storageDefinition: {}
  
  // Role assignment definitions for workload collections.
  roleAssignments: []
}
