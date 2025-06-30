@description('VNet address prefix (e.g., 10.0.0.0/16)')
param vnetAddressPrefix string

@description('Array of existing subnet prefixes (e.g., ["10.0.0.0/24", "10.0.1.0/24"])')
param existingSubnets array

@description('Prefix length for the new subnet (e.g., 27 for /27)')
param newSubnetPrefixLength int = 27

var vnetPrefixLength = int(split(vnetAddressPrefix, '/')[1])
var subnetCount = pow(2, newSubnetPrefixLength - vnetPrefixLength)

var allPossibleSubnets = [
  for i in range(0, subnetCount - 1):
    vnetPrefixLength == 16
      ? '${split(split(vnetAddressPrefix, "/")[0], ".")[0]}.${split(split(vnetAddressPrefix, "/")[0], ".")[1]}.${int(i / 8)}.${(i % 8) * 32}/${newSubnetPrefixLength}'
      : '${split(split(vnetAddressPrefix, "/")[0], ".")[0]}.${split(split(vnetAddressPrefix, "/")[0], ".")[1]}.${split(split(vnetAddressPrefix, "/")[0], ".")[2]}.${i * 32}/${newSubnetPrefixLength}'
]

// Filter out subnets that overlap with existing subnets
var availableSubnets = [
  for subnet in allPossibleSubnets:
    (!contains(existingSubnets, subnet)) ? subnet : null
]

output nextAvailableSubnet string = first([for s in availableSubnets: s if s != null])
