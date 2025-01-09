// initiative-assignment.bicep
param initiativeAssignmentName string = 'MLZGuardrailsInitiativeAssignment'
param initiativeDefinitionId string = initiativeDefinition.id
param scope string = resourceGroup().id

resource initiativeAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: initiativeAssignmentName
  properties: {
    displayName: 'Enable Azure Defender for Servers Assignment'
    policyDefinitionId: initiativeDefinitionId
    scope: scope
  }
}
