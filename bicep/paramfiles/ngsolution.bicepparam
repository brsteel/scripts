using './solution.bicep'

param hubFirewallResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/bws-dev-va-hub-rg-network/providers/Microsoft.Network/azureFirewalls/bws-dev-va-hub-afw'
param zone = ''
param tcpIdleTimeout = 4
param publicIpPrefixLength = 30

