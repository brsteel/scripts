using './combineEnclaveAndAksCluster.bicep'

// --------------------------------------------------------------------------------
// ENCLAVE PARAMETERS
// --------------------------------------------------------------------------------

// Name of the resource group to create for the Enclave.
param aveResourceGroupName = 'my-enclave-rg'

// Location for the enclave resource group and resources.
param location = 'eastus'

// Name of the enclave (Microsoft.Mission/virtualEnclaves resource name)
param enclaveName = 'my-enclave'

// Resource ID of the parent community to attach this enclave to
// Example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-community-rg/providers/Microsoft.Mission/communities/my-community
param communityResourceId = '<INSERT_COMMUNITY_RESOURCE_ID>'

// Explicit CIDR to request for the enclave base VNet (must fit inside the community address space).
param customCidrRange = '10.0.1.0/24'

// Enable Bastion access to enclave
param enableBastion = false

// Allow broad subnet-to-subnet communication (least privilege if false)
param allowSubnetCommunication = false

// Diagnostic destination: CommunityOnly | EnclaveOnly | Both | Unspecified. Must match existing enclave when updating.
param diagnosticDestination = 'EnclaveOnly'

// Tags applied to enclave and workload resources
param tags = {
  Environment: 'Development'
  Project: 'PrivateAKS'
}

// Role assignment definitions for the enclave container. Each object: { roleDefinitionId, principals: [{id,type}, ...] }.
param enclaveRoleAssignments = []

// Role assignment definitions for workload collections. Each object: { roleDefinitionId, principals: [{id,type}, ...] }.
param workloadRoleAssignments = []

// Managed identity type assigned to the enclave resource: SystemAssigned (default) or UserAssigned
param enclaveIdentityType = 'SystemAssigned'

// Resource ID of an existing user-assigned identity to attach when enclaveIdentityType = UserAssigned. Leave empty to auto-create one.
param enclaveUserAssignedIdentityResourceId = ''

// Name to use when auto-creating a user-assigned identity (ignored when resourceId is provided). Defaults to <enclaveName>-uai.
param enclaveUserAssignedIdentityName = ''

// Array of subnet definition objects.
// Example: [{ name: 'subnet1', addressPrefix: '10.0.1.0/28' }]
param subnetDefinitions = []

// AKS network overlay selection.
// Options: 'flatLegacy', 'azureCniPodSubnet', 'azureCniOverlay'
param aksNetworkOverlay = 'flatLegacy'

// Automatically create the AVE community endpoint and enclave connection required for AKS outbound connectivity.
param enableAksRequiredConnectivity = true

// Comma-separated list of CIDR ranges to use for the AKS community connection source. Leave empty to default to customCidrRange.
param aksRequiredSourceCidrs = ''

// Optional list of subnet names to dynamically resolve to CIDR ranges for the AKS community connection source. If provided, overrides aksRequiredSourceCidrs.
param aksRequiredSourceSubnetNames = []

// Optional override for the generated AKS community endpoint definition.
param aksRequiredEndpointDefinition = {}

// Optional override for the generated AKS community connection definition.
param aksRequiredConnectionDefinition = {}

// Additional community endpoint + connection objects to create.
param aksUserDefinedNetworkDefinitions = []

// --------------------------------------------------------------------------------
// WORKLOAD PARAMETERS
// --------------------------------------------------------------------------------

// Subscription ID where the AKS workload resource group will be created. Defaults to the current deployment subscription.
param targetSubscriptionId = '00000000-0000-0000-0000-000000000000'

// Name of the workload to create under the enclave.
param workloadName = 'my-aks-workload'

// Name of the AKS workload resource group that will host AKS-dependent resources. Defaults to <workloadName>-rg.
param aksResourceGroupName = 'my-aks-workload-rg'

// Azure region for the AKS workload resource group. Defaults to the enclave location.
param aksResourceGroupLocation = 'eastus'

// AKS configuration overrides (cluster, networking, diagnostics, identity). Empty object applies defaults derived from the workload name and enclave inputs.
/* Example:
{
  nodePools: [
    {
      name: 'agentpool'
      vmSize: 'Standard_D4s_v5'
      count: 3
    }
  ]
}
*/
param aksDefinition = {}

// Key Vault configuration overrides for the workload stack (name, SKU, DNS, private endpoint subnet).
param keyVaultDefinition = {}

// Storage account configuration overrides for the workload stack (name, SKU, DNS, private endpoint subnet).
param storageDefinition = {}

// Name of the enclave-managed resource group that hosts the enclave virtual network and shared resources.
// If not provided, it will be looked up from the enclave resource (if it exists) or derived.
// Note: This is NOT the resource group where the enclave resource itself lives (aveResourceGroupName), but the managed RG created by the enclave.
param managedResourceGroupName = 'my-enclave-managed-rg'

// Resource ID of the community managed resource group meant to host the firewall
// Example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-community-managed-rg
param communityManagedResourceGroupResourceId = '<INSERT_COMMUNITY_MANAGED_RG_ID>'

// Resource ID of the Resource Group where Private DNS Zones should be created/linked.
// If empty, defaults to the AKS workload resource group (legacy behavior).
// If provided, the Centralized DNS pattern is used, and zones are created/linked in this RG.
// Example: /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/central-dns-rg
param privateDnsResourceGroupId = ''
