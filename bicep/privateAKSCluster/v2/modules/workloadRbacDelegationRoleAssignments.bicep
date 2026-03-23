targetScope = 'resourceGroup'

@description('Subscription ID used for deterministic role assignment names.')
param targetSubscriptionId string

@description('Resource group name used for deterministic role assignment names.')
param targetResourceGroupName string

@description('Role definition resource ID to assign at resource group scope.')
param roleDefinitionId string

@description('Principals to assign the role to. Each item should include id and optional type (Group, User, or ServicePrincipal).')
param principals array

resource workloadRbacAdminAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principal in principals: {
  name: guid(targetSubscriptionId, targetResourceGroupName, roleDefinitionId, string(principal.id), 'workload-rbac-admin')
  properties: {
    principalId: string(principal.id)
    roleDefinitionId: roleDefinitionId
    principalType: toLower(string(contains(principal, 'type') ? principal.type : 'ServicePrincipal')) == 'group'
      ? 'Group'
      : (toLower(string(contains(principal, 'type') ? principal.type : 'ServicePrincipal')) == 'user'
          ? 'User'
          : 'ServicePrincipal')
  }
}]

output assignmentsApplied int = length(principals)
