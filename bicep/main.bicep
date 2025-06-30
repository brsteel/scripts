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
param ipsecHash object = null
//param ipsecHash object = {
//  ikeEncryption: 'AES256'
//  ikeIntegrity: 'SHA256'
//  ipsecEncryption: 'AES256'
//  ipsecIntegrity: 'SHA256'
//  dhGroup: 'DHGroup14'
//  pfsGroup: 'PFS2048'
//}

module vpnGatewayModule 'modules/vpn-gateway.bicep' = {
  name: 'vpnGatewayModule'
  params: {
    location: location
    publicIPAddressName: publicIPAddressName
    publicIPAddressSku: publicIPAddressSku
    publicIPAddressAllocationMethod: publicIPAddressAllocationMethod
    vpnGatewayName: vpnGatewayName
    vpnType: vpnType
    vpnGatewaySku: vpnGatewaySku
    azureBgpAsn: azureBgpAsn
    connectionId: connectionId
    connectionName: connectionName
    connectionBandwidth: connectionBandwidth
    dpdTimeoutSeconds: dpdTimeoutSeconds
    enableBgp: enableBgp
    enableInternetSecurity: enableInternetSecurity
    enableRateLimiting: enableRateLimiting
    ipsecPolicies: ipsecPolicies
    remoteVpnSiteId: remoteVpnSiteId
    associatedRouteTableId: associatedRouteTableId
    inboundRouteMapId: inboundRouteMapId
    outboundRouteMapId: outboundRouteMapId
    propagatedRouteTableId: propagatedRouteTableId
    propagatedRouteTableLabel: propagatedRouteTableLabel
    staticRouteAddressPrefix: staticRouteAddressPrefix
    staticRouteName: staticRouteName
    staticRouteNextHopIpAddress: staticRouteNextHopIpAddress
    vnetLocalRouteOverrideCriteria: vnetLocalRouteOverrideCriteria
    routingWeight: routingWeight
    sharedKey: sharedKey
    trafficSelectorPolicies: trafficSelectorPolicies
    useLocalAzureIpAddress: useLocalAzureIpAddress
    usePolicyBasedTrafficSelectors: usePolicyBasedTrafficSelectors
    vpnConnectionProtocolType: vpnConnectionProtocolType
    vpnLinkConnections: vpnLinkConnections
    enableBgpRouteTranslationForNat: enableBgpRouteTranslationForNat
    isRoutingPreferenceInternet: isRoutingPreferenceInternet
    natRules: natRules
    virtualHubId: virtualHubId
    vpnGatewayScaleUnit: vpnGatewayScaleUnit
    localNetworkGatewayName: localNetworkGatewayName
    localNetworkGatewayIpAddress: localNetworkGatewayIpAddress
    localNetworkGatewayAddressPrefix: localNetworkGatewayAddressPrefix
    onPremisesBgpAsn: onPremisesBgpAsn
    ipsecHash: ipsecHash != null ? {
      ikeEncryption: ipsecHash.ikeEncryption
      ikeIntegrity: ipsecHash.ikeIntegrity
      ipsecEncryption: ipsecHash.ipsecEncryption
      ipsecIntegrity: ipsecHash.ipsecIntegrity
      dhGroup: ipsecHash.dhGroup
      pfsGroup: ipsecHash.pfsGroup
    } : null
  }
}

output vpnGatewayId string = vpnGatewayModule.outputs.vpnGatewayId
output localNetworkGatewayId string = vpnGatewayModule.outputs.localNetworkGatewayId
