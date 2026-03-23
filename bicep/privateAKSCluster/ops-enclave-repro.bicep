targetScope = 'subscription'

type roleAssignmentPrincipal = {
  id: string
  type: string
}

type roleAssignmentMapping = {
  roleDefinitionId: string
  principals: roleAssignmentPrincipal[]
}

@description('Deployment location and resource group location.')
param location string

@description('Resource group that will host the enclave.')
param enclaveResourceGroupName string

@description('Enclave resource name.')
param enclaveName string

@description('Community resource ID for enclave attachment.')
param communityResourceId string

@description('Custom CIDR range for enclave virtual network.')
param customCidrRange string

@description('Whether broad subnet communication is enabled.')
param allowSubnetCommunication bool = true

@description('Whether bastion is enabled on enclave.')
param enableBastion bool = false

@description('Diagnostic destination for enclave defaults.')
param diagnosticDestination string = 'EnclaveOnly'

@description('Tags for enclave resource group and enclave resource.')
param tags object = {}

@description('Subnet definitions for enclave virtual network.')
param subnetDefinitions array

@description('Enclave role assignments payload.')
param enclaveRoleAssignments roleAssignmentMapping[] = []

@description('Workload role assignments payload.')
param workloadRoleAssignments roleAssignmentMapping[] = []

var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var enclaveRoleDefinitionIds = [for assignment in enclaveRoleAssignments: assignment.roleDefinitionId]
var contributorIndex = indexOf(enclaveRoleDefinitionIds, contributorRoleDefinitionId)
var maintenancePrincipals = contributorIndex == -1 ? [] : enclaveRoleAssignments[contributorIndex].principals

resource enclaveRg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: enclaveResourceGroupName
  location: location
  tags: tags
}

module enclaveCreate '../../../virtual-enclaves/service-catalog/bicep/templates/privateAKSCluster/modules/enclaveResources.bicep' = {
  name: 'ops-enclave-repro-${uniqueString(enclaveName)}'
  scope: enclaveRg
  params: {
    enclaveName: enclaveName
    communityResourceId: communityResourceId
    customCidrRange: customCidrRange
    enableBastion: enableBastion
    allowSubnetCommunication: allowSubnetCommunication
    diagnosticDestination: diagnosticDestination
    tags: tags
    enclaveRoleAssignments: enclaveRoleAssignments
    workloadRoleAssignments: workloadRoleAssignments
    enclaveIdentityType: 'SystemAssigned'
    subnetDefinitions: subnetDefinitions
  }
}

output enclaveResourceId string = enclaveCreate.outputs.enclaveResourceId
output maintenancePrincipals array = maintenancePrincipals
