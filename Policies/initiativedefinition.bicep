// initiative-definition.bicep
resource initiativeDefinition 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  scope: subscription().id
  name: 'MLZInitiative'
  properties: {
    displayName: 'Mission Landing Zone Guardrails Initiative'
    description: 'This initiative ensures specific policy definitions are enforced using effects like deny and deployifnotexist, etc.'
    metadata: {
      category: 'Security and Compliance'
    }
    policyDefinitions: [
      {
        policyDefinitionId: policyDefinition.id
      }
    ]
  }
}
