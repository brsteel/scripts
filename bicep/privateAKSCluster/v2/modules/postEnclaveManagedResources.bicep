targetScope = 'subscription'

@description('Target subscription ID containing the managed resource group.')
param targetSubscriptionId string

@description('Managed resource group name created by AVE for the enclave.')
param managedResourceGroupName string

@description('Name of the enclave. Used to resolve enclave VNet by convention.')
param enclaveName string

@description('Deployment location for route table resources.')
param location string

@description('Route table name to create for egress.')
param egressRouteTableName string = 'rt-aks-egress'

@description('Subnet names to associate to the egress route table.')
param egressSubnetNames array = []

@description('Subnet communication rule definitions.')
param allowedSubnetCommunications array = []

@description('Prefix for generated NSG rule names.')
param ruleNamePrefix string = 'allow-subnet'

@description('Starting priority for generated NSG rules when not explicitly provided.')
param priorityStart int = 3000

@description('Tags for created resources.')
param tags object = {}

module egressRouteTableAssociation 'enclaveEgressRouteTable.bicep' = if (length(egressSubnetNames) > 0) {
  scope: resourceGroup(targetSubscriptionId, managedResourceGroupName)
  params: {
    enclaveName: enclaveName
    location: location
    routeTableName: egressRouteTableName
    subnetNames: egressSubnetNames
    tags: tags
  }
}

module subnetCommunicationRules 'enclaveSubnetCommunicationRules.bicep' = if (length(allowedSubnetCommunications) > 0) {
  scope: resourceGroup(targetSubscriptionId, managedResourceGroupName)
  params: {
    enclaveName: enclaveName
    allowedSubnetCommunications: allowedSubnetCommunications
    ruleNamePrefix: ruleNamePrefix
    priorityStart: priorityStart
  }
}

output routeTableId string = length(egressSubnetNames) > 0
  ? egressRouteTableAssociation.outputs.routeTableId
  : ''
output subnetCommunicationRulesApplied int = length(allowedSubnetCommunications) > 0 ? subnetCommunicationRules.outputs.rulesApplied : 0
