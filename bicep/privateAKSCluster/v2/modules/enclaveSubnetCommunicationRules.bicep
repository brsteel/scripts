targetScope = 'resourceGroup'

@description('Name of the enclave used to resolve the managed VNet name by convention (<enclaveName>-vnet).')
param enclaveName string

@description('Subnet communication rule definitions. Each object: { sourceSubnetName, destinationSubnetName, direction?, protocol?, sourcePortRange?, destinationPortRange?, priority? }. Direction supports inbound|outbound|both (default).')
param allowedSubnetCommunications array

@description('Prefix for generated NSG rule names.')
param ruleNamePrefix string = 'allow-subnet'

@description('Starting priority for generated NSG rules when not explicitly provided.')
param priorityStart int = 3000

resource enclaveVnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: '${enclaveName}-vnet'
}

var subnetPrefixByName = {
  for subnet in enclaveVnet.properties.subnets: subnet.name: string(
    contains(subnet.properties, 'addressPrefix')
      ? subnet.properties.addressPrefix
      : first(subnet.properties.addressPrefixes)
  )
}

var normalizedRules = [for (rule, idx) in allowedSubnetCommunications: {
  sourceSubnetName: contains(rule, 'sourceSubnetName') ? string(rule.sourceSubnetName) : ''
  destinationSubnetName: contains(rule, 'destinationSubnetName') ? string(rule.destinationSubnetName) : ''
  sourceNsgName: contains(rule, 'sourceNsgName') ? string(rule.sourceNsgName) : ''
  destinationNsgName: contains(rule, 'destinationNsgName') ? string(rule.destinationNsgName) : ''
  sourceSubnetPrefix: contains(rule, 'sourceSubnetPrefix') && !empty(string(rule.sourceSubnetPrefix))
    ? string(rule.sourceSubnetPrefix)
    : subnetPrefixByName[contains(rule, 'sourceSubnetName') ? string(rule.sourceSubnetName) : '']
  destinationSubnetPrefix: contains(rule, 'destinationSubnetPrefix') && !empty(string(rule.destinationSubnetPrefix))
    ? string(rule.destinationSubnetPrefix)
    : subnetPrefixByName[contains(rule, 'destinationSubnetName') ? string(rule.destinationSubnetName) : '']
  direction: contains(rule, 'direction') ? toLower(string(rule.direction)) : 'both'
  protocol: contains(rule, 'protocol') ? string(rule.protocol) : '*'
  sourcePortRange: contains(rule, 'sourcePortRange') ? string(rule.sourcePortRange) : '*'
  destinationPortRange: contains(rule, 'destinationPortRange') ? string(rule.destinationPortRange) : '*'
  priority: contains(rule, 'priority') ? int(rule.priority) : (priorityStart + (idx * 10))
}]

var sourceNsgNames = [for rule in normalizedRules: rule.sourceNsgName]
var destinationNsgNames = [for rule in normalizedRules: rule.destinationNsgName]
var sourceSubnetPrefixes = [for rule in normalizedRules: rule.sourceSubnetPrefix]
var destinationSubnetPrefixes = [for rule in normalizedRules: rule.destinationSubnetPrefix]

resource sourceNsgs 'Microsoft.Network/networkSecurityGroups@2023-09-01' existing = [for name in sourceNsgNames: {
  name: name
}]

resource destinationNsgs 'Microsoft.Network/networkSecurityGroups@2023-09-01' existing = [for name in destinationNsgNames: {
  name: name
}]

resource outboundRules 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = [for (rule, idx) in normalizedRules: if (rule.direction == 'both' || rule.direction == 'outbound') {
  parent: sourceNsgs[idx]
  name: substring('${ruleNamePrefix}-out-${idx}', 0, min(length('${ruleNamePrefix}-out-${idx}'), 80))
  properties: {
    protocol: rule.protocol
    sourcePortRange: rule.sourcePortRange
    destinationPortRange: rule.destinationPortRange
    sourceAddressPrefix: sourceSubnetPrefixes[idx]
    destinationAddressPrefix: destinationSubnetPrefixes[idx]
    access: 'Allow'
    priority: rule.priority
    direction: 'Outbound'
  }
}]

resource inboundRules 'Microsoft.Network/networkSecurityGroups/securityRules@2023-09-01' = [for (rule, idx) in normalizedRules: if (rule.direction == 'both' || rule.direction == 'inbound') {
  parent: destinationNsgs[idx]
  name: substring('${ruleNamePrefix}-in-${idx}', 0, min(length('${ruleNamePrefix}-in-${idx}'), 80))
  properties: {
    protocol: rule.protocol
    sourcePortRange: rule.sourcePortRange
    destinationPortRange: rule.destinationPortRange
    sourceAddressPrefix: sourceSubnetPrefixes[idx]
    destinationAddressPrefix: destinationSubnetPrefixes[idx]
    access: 'Allow'
    priority: rule.direction == 'both' ? rule.priority + 1 : rule.priority
    direction: 'Inbound'
  }
}]

output rulesApplied int = length(normalizedRules)
