param location string
param publicIPAddressName string
param publicIPAddressSku string
param publicIPAddressAllocationMethod string
param vpnGatewayName string
param vpnType string
param vpnGatewaySku string
param azureBgpAsn int?
param connectionId string
param connectionName string
param connectionBandwidth int
param dpdTimeoutSeconds int
param enableBgp bool
param enableInternetSecurity bool
param enableRateLimiting bool
param ipsecPolicies array
param remoteVpnSiteId string
param associatedRouteTableId string
param inboundRouteMapId string
param outboundRouteMapId string
param propagatedRouteTableId string
param propagatedRouteTableLabel string
param staticRouteAddressPrefix string
param staticRouteName string
param staticRouteNextHopIpAddress string
param vnetLocalRouteOverrideCriteria string
param routingWeight int
param sharedKey string
param trafficSelectorPolicies array
param useLocalAzureIpAddress bool
param usePolicyBasedTrafficSelectors bool
param vpnConnectionProtocolType string
param vpnLinkConnections array
param enableBgpRouteTranslationForNat bool
param isRoutingPreferenceInternet bool
param natRules array
param virtualHubId string
param vpnGatewayScaleUnit int
param localNetworkGatewayName string
param localNetworkGatewayIpAddress string
param localNetworkGatewayAddressPrefix string
param onPremisesBgpAsn int?
param ipsecHash object?

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: publicIPAddressSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAddressAllocationMethod
  }
}

resource vpnGateway 'Microsoft.Network/vpnGateways@2023-11-01' = {
  name: vpnGatewayName
  location: location
  properties: {
    bgpSettings: azureBgpAsn != null ? {
      asn: azureBgpAsn
    } : null
    connections: [
      {
        id: connectionId
        name: connectionName
        properties: {
          connectionBandwidth: connectionBandwidth
          dpdTimeoutSeconds: dpdTimeoutSeconds
          enableBgp: enableBgp
          enableInternetSecurity: enableInternetSecurity
          enableRateLimiting: enableRateLimiting
          ipsecPolicies: ipsecPolicies
          remoteVpnSite: {
            id: remoteVpnSiteId
          }
          routingConfiguration: {
            associatedRouteTable: {
              id: associatedRouteTableId
            }
            inboundRouteMap: {
              id: inboundRouteMapId
            }
            outboundRouteMap: {
              id: outboundRouteMapId
            }
            propagatedRouteTables: {
              ids: [
                {
                  id: propagatedRouteTableId
                }
              ]
              labels: [
                propagatedRouteTableLabel
              ]
            }
            vnetRoutes: {
              staticRoutes: [
                {
                  addressPrefixes: [
                    staticRouteAddressPrefix
                  ]
                  name: staticRouteName
                  nextHopIpAddress: staticRouteNextHopIpAddress
                }
              ]
              staticRoutesConfig: {
                vnetLocalRouteOverrideCriteria: vnetLocalRouteOverrideCriteria
              }
            }
          }
          routingWeight: routingWeight
          sharedKey: sharedKey
          trafficSelectorPolicies: trafficSelectorPolicies
          useLocalAzureIpAddress: useLocalAzureIpAddress
          usePolicyBasedTrafficSelectors: usePolicyBasedTrafficSelectors
          vpnConnectionProtocolType: vpnConnectionProtocolType
          vpnLinkConnections: vpnLinkConnections
        }
      }
    ]
    enableBgpRouteTranslationForNat: enableBgpRouteTranslationForNat
    isRoutingPreferenceInternet: isRoutingPreferenceInternet
    natRules: natRules
    virtualHub: {
      id: virtualHubId
    }
    vpnGatewayScaleUnit: vpnGatewayScaleUnit
  }
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-04-01' = if (onPremisesBgpAsn != null) {
  name: localNetworkGatewayName
  location: location
  properties: {
    gatewayIpAddress: localNetworkGatewayIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: [
        localNetworkGatewayAddressPrefix
      ]
    }
    bgpSettings: {
      asn: onPremisesBgpAsn
      bgpPeeringAddress: localNetworkGatewayIpAddress
    }
  }
  dependsOn: [
    vpnGateway
  ]
}

resource vpnConnection 'Microsoft.Network/connections@2023-04-01' = if (azureBgpAsn != null && onPremisesBgpAsn != null) {
  name: connectionName
  location: location
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: vpnGateway.id
      properties: {
        vpnType: vpnType
        enableBgp: azureBgpAsn != null
        activeActive: false
        gatewayDefaultSite: null
        sku: {
          name: vpnGatewaySku
          tier: vpnGatewaySku
        }
      }
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
      properties: {
        gatewayIpAddress: localNetworkGatewayIpAddress
        localNetworkAddressSpace: {
          addressPrefixes: [
            localNetworkGatewayAddressPrefix
          ]
        }
        bgpSettings: onPremisesBgpAsn != null ? {
          asn: onPremisesBgpAsn
          bgpPeeringAddress: localNetworkGatewayIpAddress
        } : null
      }
    }
    sharedKey: sharedKey
    enableBgp: true
    ipsecPolicies: ipsecHash != null ? [ipsecHash] : []
  }
}

output vpnGatewayId string = vpnGateway.id
output localNetworkGatewayId string = onPremisesBgpAsn != null ? localNetworkGateway.id : ''
