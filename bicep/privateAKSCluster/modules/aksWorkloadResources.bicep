targetScope = 'resourceGroup'

@description('Mission workload name (used for naming derived resources).')
param workloadName string

@description('Azure region for all AKS workload resources.')
param location string

@description('Resource ID of the parent Mission enclave (used to derive VNet/subnet references).')
param enclaveResourceId string

@description('Tags applied to all AKS workload resources.')
param tags object = {}

@secure()
@description('AKS configuration overrides (cluster, networking, diagnostics, identity).')
param aksDefinition object = {}

@description('Key Vault configuration overrides for the workload stack (name, SKU, DNS, private endpoint subnet).')
param keyVaultDefinition object = {}

@description('Storage account configuration overrides for the workload stack (name, SKU, DNS, private endpoint subnet).')
param storageDefinition object = {}

@description('Name of the enclave-managed resource group that hosts shared enclave resources (VNet, private endpoints, etc.).')
param managedResourceGroupName string = ''

@description('Resource ID of the community managed resource group meant to host the firewall')
param communityManagedResourceGroupResourceId string

@description('Optional Resource ID of the Resource Group where Private DNS Zones will be created/linked. If empty, defaults to the AKS Workload Resource Group.')
param privateDnsResourceGroupId string = ''


var enclaveName = last(split(enclaveResourceId, '/'))

var aksConfig = union({
  clusterName: toLower('${workloadName}-aks')
  kubernetesVersion: '1.33.5'
  diskEncryptionSetName: ''
  networkPlugin: 'azure'
  loadBalancerSku: 'standard'
  networkPolicy: 'azure'
  enableAzurePolicy: true
  outboundType: 'userDefinedRouting'
  skuTier: 'Standard'
}, aksDefinition)

var nodePoolDefaults = {
  name: 'systempool'
  vmSize: 'Standard_D4s_v5'
  osDiskSizeGB: 128
  count: 3
  minCount: 3
  maxCount: 5
  maxPods: 30
  enableAutoScaling: true
  availabilityZones: []
  mode: 'System'
  type: 'VirtualMachineScaleSets'
  scaleSetPriority: 'Regular'
  osType: 'Linux'
  enableFips: true
  associateRouteTable: true
  subnetName: ''
}

var nodePoolsRaw = contains(aksDefinition, 'nodePools') && !empty(aksDefinition.nodePools) ? aksDefinition.nodePools : [
  {}
]
var requestedNodePools = [for pool in nodePoolsRaw: union(nodePoolDefaults, pool)]
var nodePoolSubnetsWithRouteTable = [for pool in requestedNodePools: pool.associateRouteTable && contains(pool, 'subnetName') ? pool.subnetName : '']
var uniqueNodePoolSubnetsWithRouteTable = filter(nodePoolSubnetsWithRouteTable, (s) => !empty(s))

var networkProfileOverrides = contains(aksDefinition, 'networkProfile') && !empty(aksDefinition.networkProfile) ? aksDefinition.networkProfile : {}
var networkProfileConfig = union({
  serviceCidr: '10.2.0.0/16'
  dnsServiceIP: '10.2.0.10'
}, empty(networkProfileOverrides) ? {} : networkProfileOverrides)

var diagnosticsOverrides = contains(aksDefinition, 'diagnostics') && !empty(aksDefinition.diagnostics) ? aksDefinition.diagnostics : {}
var diagnosticsConfig = union({
  mode: 'WorkloadOnly'
  workspace: {}
}, empty(diagnosticsOverrides) ? {} : diagnosticsOverrides)

var diagnosticsWorkspaceOverrides = diagnosticsConfig.workspace
var diagnosticsWorkspaceConfig = union({
  name: ''
  skuName: 'PerGB2018'
  retentionInDays: 30
  dailyQuotaGb: -1
  publicNetworkAccessForIngestion: 'Disabled'
  publicNetworkAccessForQuery: 'Disabled'
  enableLogAccessUsingOnlyResourcePermissions: true
}, empty(diagnosticsWorkspaceOverrides) ? {} : diagnosticsWorkspaceOverrides)

var diagnosticsMode = toLower(string(diagnosticsConfig.mode))
var diagnosticsModeWorkloadAndEnclave = diagnosticsMode == 'workloadandenclave'

var resolvedWorkloadLogAnalyticsNameSeed = format('{0}-loga-{1}', normalizedWorkloadSegment, substring(uniqueString(resourceGroup().id, workloadName, 'loga'), 0, 4))
var resolvedWorkloadLogAnalyticsNameLength = min(length(resolvedWorkloadLogAnalyticsNameSeed), 63)
var resolvedWorkloadLogAnalyticsName = toLower(empty(string(diagnosticsWorkspaceConfig.name))
  ? substring(resolvedWorkloadLogAnalyticsNameSeed, 0, resolvedWorkloadLogAnalyticsNameLength)
  : string(diagnosticsWorkspaceConfig.name))
var resolvedWorkloadLogAnalyticsSkuName = empty(string(diagnosticsWorkspaceConfig.skuName)) ? 'PerGB2018' : string(diagnosticsWorkspaceConfig.skuName)
var resolvedWorkloadLogAnalyticsRetentionInDays = contains(diagnosticsWorkspaceConfig, 'retentionInDays') ? int(diagnosticsWorkspaceConfig.retentionInDays) : 30
var resolvedWorkloadLogAnalyticsDailyQuotaGb = contains(diagnosticsWorkspaceConfig, 'dailyQuotaGb') ? int(diagnosticsWorkspaceConfig.dailyQuotaGb) : -1
var resolvedWorkloadLogAnalyticsPublicAccessIngestion = empty(string(diagnosticsWorkspaceConfig.publicNetworkAccessForIngestion)) ? 'Disabled' : string(diagnosticsWorkspaceConfig.publicNetworkAccessForIngestion)
var resolvedWorkloadLogAnalyticsPublicAccessQuery = empty(string(diagnosticsWorkspaceConfig.publicNetworkAccessForQuery)) ? 'Disabled' : string(diagnosticsWorkspaceConfig.publicNetworkAccessForQuery)
var resolvedLogAccessPermissionOnly = contains(diagnosticsWorkspaceConfig, 'enableLogAccessUsingOnlyResourcePermissions') ? bool(diagnosticsWorkspaceConfig.enableLogAccessUsingOnlyResourcePermissions) : true

var defenderOverrides = contains(aksDefinition, 'defender') && !empty(aksDefinition.defender) ? aksDefinition.defender : {}
var defenderConfig = union({
  enabled: true
}, empty(defenderOverrides) ? {} : defenderOverrides)

var identityOverrides = contains(aksDefinition, 'identity') && !empty(aksDefinition.identity) ? aksDefinition.identity : {}
var identityConfig = union({
  createUserAssignedIdentity: false
  userAssignedIdentityResourceId: ''
  identityName: ''
  roleAssignments: []
}, empty(identityOverrides) ? {} : identityOverrides)

var aadProfileOverrides = contains(aksDefinition, 'aadProfile') && !empty(aksDefinition.aadProfile) ? aksDefinition.aadProfile : {}
var aadProfileDefaults = {
  enableAzureRBAC: true
  managed: true
  adminGroupObjectIDs: []
}
var aadProfileConfig = union(aadProfileDefaults, empty(aadProfileOverrides) ? {} : aadProfileOverrides)
var aadProfileAdminGroupsRaw = aadProfileConfig.adminGroupObjectIDs
var aadProfileAdminGroups = empty(aadProfileAdminGroupsRaw) ? [] : aadProfileAdminGroupsRaw
var aadProfileEnabled = bool(aadProfileConfig.enableAzureRBAC)
var resolvedAadProfile = aadProfileEnabled
  ? {
      managed: bool(aadProfileConfig.managed)
      enableAzureRBAC: true
      adminGroupObjectIDs: aadProfileAdminGroups
    }
  : null
var disableLocalAccountsSetting = contains(aksDefinition, 'disableLocalAccounts') ? bool(aksDefinition.disableLocalAccounts) : true

var addonProfilesConfig = contains(aksDefinition, 'addonProfiles') && !empty(aksDefinition.addonProfiles)
  ? aksDefinition.addonProfiles
  : {}

var keyVaultConfig = union({
  name: ''
  skuName: 'premium'
  privateDnsZoneName: ''
  privateEndpointSubnetName: ''
}, empty(keyVaultDefinition) ? {} : keyVaultDefinition)

var storageConfig = union({
  name: ''
  skuName: 'Standard_LRS'
  privateDnsZoneName: ''
  kind: 'StorageV2'
  privateEndpointSubnetName: ''
}, empty(storageDefinition) ? {} : storageDefinition)

var enclaveSegments = split(enclaveResourceId, '/')
var enclaveSubscriptionId = length(enclaveSegments) > 2 ? enclaveSegments[2] : subscription().subscriptionId
var managedResourceGroupNameLower = toLower(managedResourceGroupName)

var normalizedWorkloadSegment = toLower(replace(replace(workloadName, '-', ''), '_', ''))
var nameSeed = uniqueString(resourceGroup().id, workloadName)
var resolvedAksClusterName = toLower(empty(string(aksConfig.clusterName)) ? '${workloadName}-aks' : string(aksConfig.clusterName))
var dnsPrefixSeed = toLower(replace(resolvedAksClusterName, '_', '-'))
var dnsPrefixLength = length(dnsPrefixSeed) < 54 ? length(dnsPrefixSeed) : 54
var resolvedDnsPrefix = substring(dnsPrefixSeed, 0, dnsPrefixLength)
var kubernetesVersion = string(aksConfig.kubernetesVersion)
var keyVaultPrivateEndpointSubnetName = string(keyVaultConfig.privateEndpointSubnetName)
var storagePrivateEndpointSubnetName = string(storageConfig.privateEndpointSubnetName)

module enclaveContext './enclaveContext.bicep' = {
  name: 'enclaveContext-${uniqueString(resourceGroup().id, workloadName)}'
  params: {
    enclaveResourceId: enclaveResourceId
    managedResourceGroupName: managedResourceGroupName
    // Only pass this if we intend to use the firewall (UDR mode). Passing empty string skips the lookup.
    communityManagedResourceGroupResourceId: aksConfig.outboundType == 'userDefinedRouting' ? communityManagedResourceGroupResourceId : ''
  }
}

var enclaveLogAnalyticsCollection = array(enclaveContext.outputs.logAnalyticsResourceIds)
var enclaveSubnetConfigurations = array(enclaveContext.outputs.subnetConfigurations)
var fallbackVirtualNetworkResourceId = string(enclaveContext.outputs.virtualNetworkResourceId)

var keyVaultPrivateEndpointSubnetMatches = !empty(keyVaultPrivateEndpointSubnetName)
  ? filter(enclaveSubnetConfigurations, (s) => contains(s, 'subnetName') && !empty(s.subnetName) && toLower(string(s.subnetName)) == toLower(keyVaultPrivateEndpointSubnetName))
  : []
var keyVaultPrivateEndpointSubnetResourceId = length(keyVaultPrivateEndpointSubnetMatches) > 0 && contains(keyVaultPrivateEndpointSubnetMatches[0], 'subnetResourceId') && !empty(keyVaultPrivateEndpointSubnetMatches[0].subnetResourceId)
  ? string(keyVaultPrivateEndpointSubnetMatches[0].subnetResourceId)
  : ''
var storagePrivateEndpointSubnetMatches = !empty(storagePrivateEndpointSubnetName)
  ? filter(enclaveSubnetConfigurations, (s) => contains(s, 'subnetName') && !empty(s.subnetName) && toLower(string(s.subnetName)) == toLower(storagePrivateEndpointSubnetName))
  : []
var storagePrivateEndpointSubnetResourceId = length(storagePrivateEndpointSubnetMatches) > 0 && contains(storagePrivateEndpointSubnetMatches[0], 'subnetResourceId') && !empty(storagePrivateEndpointSubnetMatches[0].subnetResourceId)
  ? string(storagePrivateEndpointSubnetMatches[0].subnetResourceId)
  : ''

// Use fallback virtual network resource ID since we don't have explicit node subnet anymore
var constructedVnetId = '/subscriptions/${split(enclaveResourceId, '/')[2]}/resourceGroups/${managedResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${enclaveName}-vnet'
var virtualNetworkResourceId = constructedVnetId
var resolvedFirewallPrivateIp = string(enclaveContext.outputs.firewallPrivateIp)

// Only deploy the Egress Route Table if the AKS cluster is configured for User Defined Routing
// If outboundType is 'loadBalancer' or 'managedNATGateway', we should NOT force traffic to the firewall.
module aksNetworkConfig './aksNetworkConfig.bicep' = if (!empty(managedResourceGroupName) && aksConfig.outboundType == 'userDefinedRouting') {
  name: 'aks-network-config-${uniqueString(workloadName)}'
  scope: resourceGroup(enclaveSubscriptionId, managedResourceGroupName)
  params: {
    location: location
    tags: tags
    vnetName: '${enclaveName}-vnet'
    subnetNames: uniqueNodePoolSubnetsWithRouteTable
    firewallPrivateIp: resolvedFirewallPrivateIp
  }
}

var networkServiceCidr = string(networkProfileConfig.serviceCidr)
var networkDnsServiceIP = string(networkProfileConfig.dnsServiceIP)
var enableDefender = bool(defenderConfig.enabled)
var resolvedAddonProfiles = union(length(addonProfilesConfig) > 0 ? addonProfilesConfig : {}, {
  azurepolicy: {
    enabled: bool(aksConfig.enableAzurePolicy)
  }
})
var apiServerAccessProfileBase = {
  enablePrivateCluster: true
}
var apiServerAccessProfileConfig = apiServerAccessProfileBase
var managedResourceGroupMatchFragment = empty(managedResourceGroupNameLower) ? '' : format('/resourcegroups/{0}/', managedResourceGroupNameLower)
var enclaveLogAnalyticsMatches = filter(enclaveLogAnalyticsCollection, (workspaceId) => !empty(managedResourceGroupMatchFragment) && contains(toLower(string(workspaceId)), managedResourceGroupMatchFragment))
var derivedEnclaveLogAnalyticsResourceId = length(enclaveLogAnalyticsMatches) > 0
  ? string(enclaveLogAnalyticsMatches[0])
  : (length(enclaveLogAnalyticsCollection) > 1
      ? string(enclaveLogAnalyticsCollection[1])
      : (length(enclaveLogAnalyticsCollection) > 0 ? string(enclaveLogAnalyticsCollection[0]) : ''))
var workloadLogAnalyticsResourceId = resourceId('Microsoft.OperationalInsights/workspaces', resolvedWorkloadLogAnalyticsName)
var enclaveLogAnalyticsResourceId = empty(string(derivedEnclaveLogAnalyticsResourceId)) ? '' : string(derivedEnclaveLogAnalyticsResourceId)
var workloadDiagnosticsEnabled = true
var enclaveDiagnosticsEnabled = diagnosticsModeWorkloadAndEnclave
var diagnosticsEnabled = workloadDiagnosticsEnabled || enclaveDiagnosticsEnabled
var primaryWorkspaceId = workloadLogAnalyticsResourceId
var keyVaultDiagnosticSettings = {
  logs: [
    {
      category: 'AuditEvent'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
  ]
  metrics: [
    {
      category: 'AllMetrics'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
  ]
}
var storageDiagnosticSettings = {
  metrics: [
    {
      category: 'Transaction'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
    {
      category: 'Capacity'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
  ]
}
var aksDiagnosticSettings = {
  logs: [
    {
      category: 'kube-apiserver'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
    {
      category: 'kube-controller-manager'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
    {
      category: 'kube-scheduler'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
    {
      category: 'cluster-autoscaler'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
    {
      category: 'kube-audit'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
    {
      category: 'kube-audit-admin'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
  ]
  metrics: [
    {
      category: 'AllMetrics'
      enabled: true
      retentionPolicy: {
        enabled: false
        days: 0
      }
    }
  ]
}
// var agentPoolProfiles moved inline to resource to avoid BCP182

var defaultStorageAccountNameSeed = '${normalizedWorkloadSegment}st${nameSeed}'
var storageAccountNameLength = length(defaultStorageAccountNameSeed) < 24 ? length(defaultStorageAccountNameSeed) : 24
var resolvedStorageAccountName = empty(string(storageConfig.name)) ? substring(defaultStorageAccountNameSeed, 0, storageAccountNameLength) : toLower(string(storageConfig.name))
var defaultKeyVaultNameSeed = '${normalizedWorkloadSegment}kv${nameSeed}'
var keyVaultNameLength = length(defaultKeyVaultNameSeed) < 24 ? length(defaultKeyVaultNameSeed) : 24
var resolvedKeyVaultName = empty(string(keyVaultConfig.name)) ? substring(defaultKeyVaultNameSeed, 0, keyVaultNameLength) : toLower(string(keyVaultConfig.name))
var requestedKeyVaultSkuName = empty(string(keyVaultConfig.skuName)) ? 'premium' : toLower(string(keyVaultConfig.skuName))
var resolvedKeyVaultSkuName = requestedKeyVaultSkuName == 'standard' ? 'standard' : 'premium'
var defaultDiskEncryptionSetNameSeed = '${normalizedWorkloadSegment}des${nameSeed}'
var diskEncryptionSetNameLength = length(defaultDiskEncryptionSetNameSeed) < 80 ? length(defaultDiskEncryptionSetNameSeed) : 80
var resolvedDiskEncryptionSetName = empty(string(aksConfig.diskEncryptionSetName))
  ? substring(defaultDiskEncryptionSetNameSeed, 0, diskEncryptionSetNameLength)
  : toLower(string(aksConfig.diskEncryptionSetName))
var resolvedStorageSkuName = empty(string(storageConfig.skuName)) ? 'Standard_LRS' : string(storageConfig.skuName)
var resolvedStorageKind = empty(string(storageConfig.kind)) ? 'StorageV2' : string(storageConfig.kind)
var storageSuffix = environment().suffixes.storage
var rawKeyVaultSuffix = replace(environment().suffixes.keyvaultDns, 'vault.', '')
var keyVaultSuffix = startsWith(rawKeyVaultSuffix, '.') ? substring(rawKeyVaultSuffix, 1) : rawKeyVaultSuffix
var keyVaultPrivateDnsZoneOverride = contains(keyVaultConfig, 'privateDnsZoneName') ? string(keyVaultConfig.privateDnsZoneName) : ''
var storagePrivateDnsZoneOverride = contains(storageConfig, 'privateDnsZoneName') ? string(storageConfig.privateDnsZoneName) : ''
var resolvedStoragePrivateDnsZoneName = empty(storagePrivateDnsZoneOverride) ? format('privatelink.blob.{0}', storageSuffix) : storagePrivateDnsZoneOverride
var resolvedKeyVaultPrivateDnsZoneName = empty(keyVaultPrivateDnsZoneOverride) ? format('privatelink.vaultcore.{0}', keyVaultSuffix) : keyVaultPrivateDnsZoneOverride
var resolvedIdentityName = toLower(empty(string(identityConfig.identityName)) ? '${workloadName}-aks-uai' : string(identityConfig.identityName))

var keyVaultCryptoServiceEncryptionUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')
var keyVaultCryptoUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '12338af0-0e69-4776-bea7-57ae8d297424')
var readerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

var isUsGov = environment().name == 'AzureUSGovernment'
var acrDnsZoneName = isUsGov ? 'privatelink.azurecr.us' : 'privatelink.azurecr.io'
var monitorDnsZoneName = isUsGov ? 'privatelink.monitor.azure.us' : 'privatelink.monitor.azure.com'
var omsDnsZoneName = isUsGov ? 'privatelink.oms.opinsights.azure.us' : 'privatelink.oms.opinsights.azure.com'
var odsDnsZoneName = isUsGov ? 'privatelink.ods.opinsights.azure.us' : 'privatelink.ods.opinsights.azure.com'
var agentSvcDnsZoneName = isUsGov ? 'privatelink.agentsvc.azure.us' : 'privatelink.agentsvc.azure-automation.net'

var additionalDnsZones = [
  acrDnsZoneName
  monitorDnsZoneName
  omsDnsZoneName
  odsDnsZoneName
  agentSvcDnsZoneName
]

var shouldCreateIdentity = bool(identityConfig.createUserAssignedIdentity) || empty(resolvedUserAssignedIdentityResourceId)
var resolvedUserAssignedIdentityResourceId = string(identityConfig.userAssignedIdentityResourceId)
var normalizedIdentityRoleAssignments = identityConfig.roleAssignments
var providedIdentityScopeReady = !empty(resolvedUserAssignedIdentityResourceId)

resource aksUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (shouldCreateIdentity) {
  name: resolvedIdentityName
  location: location
  tags: union(tags, {
    'mission-component': 'aks-identity'
  })
}

var resolvedIdentityResourceKey = shouldCreateIdentity
  ? aksUserAssignedIdentity.id
  : resolvedUserAssignedIdentityResourceId

var resolvedIdentityPrincipalReferenceId = !empty(resolvedIdentityResourceKey)
  ? resolvedIdentityResourceKey
  : ''

var resolvedUserAssignedIdentityPrincipalId = !empty(resolvedIdentityPrincipalReferenceId)
  ? string(reference(resolvedIdentityPrincipalReferenceId, '2023-01-31', 'Full').properties.principalId)
  : ''

var identityRoleAssignmentNameSeed = !empty(resolvedIdentityResourceKey) ? resolvedIdentityResourceKey : resourceGroup().id

var identityRoleAssignmentsCondition = (shouldCreateIdentity || providedIdentityScopeReady) && length(normalizedIdentityRoleAssignments) > 0

resource identityRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (assignment, idx) in (identityRoleAssignmentsCondition ? normalizedIdentityRoleAssignments : []): {
  name: guid(identityRoleAssignmentNameSeed, string(assignment.roleDefinitionId), string(idx))
  properties: {
    principalId: resolvedUserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: string(assignment.roleDefinitionId)
  }
}]


var resolvedIdentity = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${resolvedIdentityResourceKey}': {}
  }
}

var addonProfiles = union(resolvedAddonProfiles, {
  omsagent: {
    enabled: true
    config: {
      logAnalyticsWorkspaceResourceID: workloadLogAnalyticsResourceId
    }
  }
})

resource workloadKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: resolvedKeyVaultName
  location: location
  tags: union(tags, {
    'mission-component': 'aks-support'
  })
  properties: {
    sku: {
      family: 'A'
      name: resolvedKeyVaultSkuName
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    publicNetworkAccess: 'Disabled'
    softDeleteRetentionInDays: 90
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

resource workloadKey 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: workloadKeyVault
  name: 'aks-kms'
  properties: {
    kty: toLower(resolvedKeyVaultSkuName) == 'premium' ? 'RSA-HSM' : 'RSA'
    keySize: 3072
    keyOps: [
      'encrypt'
      'decrypt'
      'wrapKey'
      'unwrapKey'
    ]
  }
}

resource workloadDiskEncryptionSet 'Microsoft.Compute/diskEncryptionSets@2022-07-02' = {
  name: resolvedDiskEncryptionSetName
  location: location
  tags: union(tags, {
    'mission-component': 'aks-support'
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    activeKey: {
      sourceVault: {
        id: workloadKeyVault.id
      }
      keyUrl: workloadKey.properties.keyUriWithVersion
    }
    encryptionType: 'EncryptionAtRestWithCustomerKey'
    rotationToLatestKeyVersionEnabled: true
  }
}

resource workloadDiskEncryptionSetKeyVaultAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(workloadDiskEncryptionSet.id, workloadKeyVault.id, 'des-kv-access')
  scope: workloadKeyVault
  properties: {
    principalId: workloadDiskEncryptionSet.identity.principalId
    roleDefinitionId: keyVaultCryptoServiceEncryptionUserRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

resource workloadDiskEncryptionSetKeyVaultEncryptAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(workloadDiskEncryptionSet.id, workloadKeyVault.id, 'des-kv-crypto-user')
  scope: workloadKeyVault
  properties: {
    principalId: workloadDiskEncryptionSet.identity.principalId
    roleDefinitionId: keyVaultCryptoUserRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

resource aksUserAssignedIdentityDiskEncryptionSetAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resolvedIdentityResourceKey, workloadDiskEncryptionSet.id, 'aks-uai-des-reader')
  scope: workloadDiskEncryptionSet
  properties: {
    principalId: resolvedUserAssignedIdentityPrincipalId
    roleDefinitionId: readerRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
  dependsOn: shouldCreateIdentity ? [
    aksUserAssignedIdentity
    workloadDiskEncryptionSet
  ] : [
    workloadDiskEncryptionSet
  ]
}

resource workloadStorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: resolvedStorageAccountName
  location: location
  tags: tags
  sku: {
    name: resolvedStorageSkuName
  }
  kind: resolvedStorageKind
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource workloadLogAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: resolvedWorkloadLogAnalyticsName
  location: location
  tags: union(tags, {
    'mission-component': 'aks-observability'
  })
  properties: {
    sku: {
      name: resolvedWorkloadLogAnalyticsSkuName
    }
    retentionInDays: resolvedWorkloadLogAnalyticsRetentionInDays
    publicNetworkAccessForIngestion: resolvedWorkloadLogAnalyticsPublicAccessIngestion
    publicNetworkAccessForQuery: resolvedWorkloadLogAnalyticsPublicAccessQuery
    features: {
      enableLogAccessUsingOnlyResourcePermissions: resolvedLogAccessPermissionOnly
    }
    workspaceCapping: {
      dailyQuotaGb: resolvedWorkloadLogAnalyticsDailyQuotaGb
    }
  }
}

// --------------------------------------------------------------------------------
// PRIVATE DNS CONFIGURATION
// --------------------------------------------------------------------------------

var dnsTargetSubscriptionId = !empty(privateDnsResourceGroupId) ? split(privateDnsResourceGroupId, '/')[2] : subscription().subscriptionId
var dnsTargetResourceGroupName = !empty(privateDnsResourceGroupId) ? split(privateDnsResourceGroupId, '/')[4] : resourceGroup().name

var allDnsZoneNames = union([
  resolvedKeyVaultPrivateDnsZoneName
  resolvedStoragePrivateDnsZoneName
], additionalDnsZones)

module privateDnsManager './privateDnsManagement.bicep' = {
  name: 'private-dns-manager-${uniqueString(workloadName)}'
  scope: resourceGroup(dnsTargetSubscriptionId, dnsTargetResourceGroupName)
  params: {
    dnsZoneNames: allDnsZoneNames
    vnetResourceId: virtualNetworkResourceId
    tags: tags
  }
}

// Helper to lookup ID from module output
var keyVaultZoneId = filter(privateDnsManager.outputs.dnsZoneResourceIds, (z) => z.name == resolvedKeyVaultPrivateDnsZoneName)[0].id
var storageZoneId = filter(privateDnsManager.outputs.dnsZoneResourceIds, (z) => z.name == resolvedStoragePrivateDnsZoneName)[0].id

// --------------------------------------------------------------------------------
// PRIVATE ENDPOINTS
// --------------------------------------------------------------------------------

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (!empty(keyVaultPrivateEndpointSubnetName)) {
  name: 'kv-pe-${uniqueString(resolvedKeyVaultName, workloadName)}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: keyVaultPrivateEndpointSubnetResourceId
    }
    privateLinkServiceConnections: [
      {
        name: 'keyvault'
        properties: {
          privateLinkServiceId: workloadKeyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource keyVaultPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (!empty(keyVaultPrivateEndpointSubnetName)) {
  parent: keyVaultPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: resolvedKeyVaultPrivateDnsZoneName
        properties: {
          privateDnsZoneId: keyVaultZoneId
        }
      }
    ]
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (!empty(storagePrivateEndpointSubnetName)) {
  name: 'st-pe-${uniqueString(resolvedStorageAccountName, workloadName)}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: storagePrivateEndpointSubnetResourceId
    }
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          privateLinkServiceId: workloadStorage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storagePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (!empty(storagePrivateEndpointSubnetName)) {
  parent: storagePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: resolvedStoragePrivateDnsZoneName
        properties: {
          privateDnsZoneId: storageZoneId
        }
      }
    ]
  }
}

resource aksManagedCluster 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: resolvedAksClusterName
  location: location
  tags: tags
  sku: {
    name: 'Base'
    tier: aksConfig.skuTier
  }
  identity: resolvedIdentity
  dependsOn: !empty(managedResourceGroupName) ? [
    aksNetworkConfig
  ] : []
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: resolvedDnsPrefix
    apiServerAccessProfile: apiServerAccessProfileConfig
    agentPoolProfiles: [for pool in requestedNodePools: {
      name: pool.name
      vmSize: pool.vmSize
      osDiskSizeGB: int(pool.osDiskSizeGB)
      count: int(pool.count)
      osType: pool.osType
      maxPods: int(pool.maxPods)
      mode: pool.mode
      type: pool.type
      scaleSetPriority: pool.scaleSetPriority
      availabilityZones: pool.availabilityZones == null ? [] : pool.availabilityZones
      enableAutoScaling: bool(pool.enableAutoScaling)
      vnetSubnetID: '${virtualNetworkResourceId}/subnets/${pool.subnetName}'
      enableFips: bool(pool.enableFips)
      minCount: bool(pool.enableAutoScaling) ? pool.minCount : null
      maxCount: bool(pool.enableAutoScaling) ? pool.maxCount : null
    }]
    networkProfile: {
      networkPlugin: aksConfig.networkPlugin
      networkPluginMode: contains(aksConfig, 'networkPluginMode') ? aksConfig.networkPluginMode : null
      podCidr: contains(aksConfig, 'podCidr') ? aksConfig.podCidr : null
      networkPolicy: aksConfig.networkPolicy
      serviceCidr: networkServiceCidr
      dnsServiceIP: networkDnsServiceIP
      outboundType: aksConfig.outboundType
      loadBalancerSku: aksConfig.loadBalancerSku
    }
    diskEncryptionSetID: workloadDiskEncryptionSet.id
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
    addonProfiles: addonProfiles
    aadProfile: resolvedAadProfile
    serviceMeshProfile: contains(aksDefinition, 'serviceMeshProfile') ? aksDefinition.serviceMeshProfile : null
    disableLocalAccounts: disableLocalAccountsSetting
  }
}

resource keyVaultDiagnosticsWorkload 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (workloadDiagnosticsEnabled) {
  name: 'kv-workload'
  scope: workloadKeyVault
  properties: union(keyVaultDiagnosticSettings, {
    workspaceId: workloadLogAnalyticsResourceId
  })
}

resource keyVaultDiagnosticsEnclave 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enclaveDiagnosticsEnabled) {
  name: 'kv-enclave'
  scope: workloadKeyVault
  properties: union(keyVaultDiagnosticSettings, {
    workspaceId: enclaveLogAnalyticsResourceId
  })
}

resource storageDiagnosticsWorkload 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (workloadDiagnosticsEnabled) {
  name: 'st-workload'
  scope: workloadStorage
  properties: union(storageDiagnosticSettings, {
    workspaceId: workloadLogAnalyticsResourceId
  })
}

resource storageDiagnosticsEnclave 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enclaveDiagnosticsEnabled) {
  name: 'st-enclave'
  scope: workloadStorage
  properties: union(storageDiagnosticSettings, {
    workspaceId: enclaveLogAnalyticsResourceId
  })
}

resource aksDiagnosticsWorkload 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (workloadDiagnosticsEnabled) {
  name: 'aks-workload'
  scope: aksManagedCluster
  properties: union(aksDiagnosticSettings, {
    workspaceId: workloadLogAnalyticsResourceId
  })
}

resource aksDiagnosticsEnclave 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enclaveDiagnosticsEnabled) {
  name: 'aks-enclave'
  scope: aksManagedCluster
  properties: union(aksDiagnosticSettings, {
    workspaceId: enclaveLogAnalyticsResourceId
  })
}

output virtualNetworkResourceId string = virtualNetworkResourceId
output aksClusterResourceId string = aksManagedCluster.id
output keyVaultResourceId string = workloadKeyVault.id
output storageAccountResourceId string = workloadStorage.id
output diskEncryptionSetResourceId string = workloadDiskEncryptionSet.id
output keyVaultPrivateEndpointSubnetId string = keyVaultPrivateEndpointSubnetResourceId
output storagePrivateEndpointSubnetId string = storagePrivateEndpointSubnetResourceId
output userAssignedIdentityResourceId string = resolvedUserAssignedIdentityResourceId
output userAssignedIdentityPrincipalId string = resolvedUserAssignedIdentityPrincipalId