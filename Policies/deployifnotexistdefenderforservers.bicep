// policy-definition.bicep
resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  scope: subscription().id  
  name: 'deployIfNotExistsEnableAzureDefenderForServers'
  properties: {
    displayName: 'DeployIfNotExists: Enable Azure Defender for Servers'
    policyType: 'Custom'
    mode: 'All'
    description: 'This policy ensures that Azure Defender for Servers is enabled.'
    metadata: {
      category: 'Security'
    }
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Compute/virtualMachines'
      }
      then: {
        effect: 'DeployIfNotExists'
        details: {
          type: 'Microsoft.Security/autoProvisioningSettings'
          name: 'default'
          existenceCondition: {
            field: 'Microsoft.Security/autoProvisioningSettings/autoProvision'
            equals: 'On'
          }
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
          ]
          deployment: {
            properties: {
              mode: 'incremental'
              template: {
                '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
                contentVersion: '1.0.0.0'
                resources: [
                  {
                    type: 'Microsoft.Security/autoProvisioningSettings'
                    apiVersion: '2017-08-01-preview'
                    name: 'default'
                    properties: {
                      autoProvision: 'On'
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }
  }
}
