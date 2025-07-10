using './mlz.bicep'

param additionalFwPipCount = 3
param deployIdentity = true
param deployNetworkWatcherTrafficAnalytics = true
param deployWindowsVirtualMachine = true
param emailSecurityContact = 'brsteel@microsoft.com'
param enableProxy = true
param environmentAbbreviation = 'dev'
param hubSubscriptionId = 'afb59830-1fc9-44c9-bba3-04f657483578'
param identifier = 'new'
param identitySubscriptionId = 'd9cb6670-f9bf-416f-aa7b-2d6936edcaeb'
param location = 'usgovvirginia'
param operationsSubscriptionId = '6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24'
param sharedServicesSubscriptionId = '3a8f043c-c15c-4a67-9410-a585a85f2109'
param customFirewallRuleCollectionGroups = [
  {
    name: 'MLZ-DefaultCollectionGroup'
    properties: {
      priority: 100
      ruleCollections: [
        {
          name: 'NetworkRules'
          priority: 100
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Allow-LAW-TCP'
              ruleType: 'NetworkRule'
              ipProtocols: ['Tcp']
              sourceAddresses: ['10.0.128.0/18']
              destinationAddresses: ['10.0.131.3']
              destinationPorts: ['443']
            }
            {
              name: 'Allow-ADDS-TCP'
              ruleType: 'NetworkRule'
              ipProtocols: ['TCP']
              sourceAddresses: ['10.0.128.0/18']
              destinationAddresses: ['10.0.130.3', '10.0.130.4']
              destinationPorts: [
                '53', '88', '135', '389', '445', '464', '636', '3268', '3269'
              ]
            }
            {
              name: 'Allow-ADDS-UDP'
              ruleType: 'NetworkRule'
              ipProtocols: ['UDP']
              sourceAddresses: ['10.0.128.0/18']
              destinationAddresses: ['10.0.130.3', '10.0.130.4']
              destinationPorts: [
                '53', '88', '123', '389', '464'
              ]
            }
            {
              name: 'Allow-KMS-TCP'
              ruleType: 'NetworkRule'
              ipProtocols: ['Tcp']
              sourceAddresses: ['10.0.128.132', '10.0.128.133', '10.0.130.3', '10.0.130.4']
              destinationAddresses: []
              destinationFqdns: ['azkms.core.windows.net', 'kms.core.windows.net']
              destinationPorts: ['1688']
              sourceIpGroups: []
              destinationIpGroups: []
            }
          ]
        }
        {
          name: 'ApplicationRules'
          priority: 200
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Allow-WindowsUpdate'
              ruleType: 'ApplicationRule'
              protocols: [
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: ['WindowsUpdate']
              webCategories: []
              targetFqdns: []
              targetUrls: []
              terminateTLS: false
              sourceAddresses: ['10.0.128.132', '10.0.128.133', '10.0.130.3', '10.0.130.4']
              destinationAddresses: []
              sourceIpGroups: []
            }
          ]
        }
      ]
    }
  }
  {
    name: 'CustomNatCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          name: 'CustomNatRules'
          priority: 100
          ruleCollectionType: 'FirewallPolicyNatRuleCollection'
          action: {
            type: 'Dnat'
          }
          rules: [
            {
              name: 'Custom-NAT-Rule-1'
              ruleType: 'NatRule'
              ipProtocols: ['Tcp']
              sourceAddresses: ['*']
              destinationAddresses: ['51.54.139.249']
              destinationPorts: ['3389']
              translatedAddress: '10.0.128.133'
              translatedPort: '3389'
            }
          ]
        }
      ]
    }
  }
]
