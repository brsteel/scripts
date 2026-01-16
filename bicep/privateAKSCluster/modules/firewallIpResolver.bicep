param firewallName string

resource firewall 'Microsoft.Network/azureFirewalls@2023-11-01' existing = {
  name: firewallName
}

output privateIp string = firewall.properties.hubIPAddresses.privateIPAddress
