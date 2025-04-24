using './solution.bicep'

param activeDirectorySolution = 'MicrosoftEntraId'
param domainJoinUserPrincipalName = 'xadmin@steele.local'
param fslogixContainerType = 'ProfileContainer'
param fslogixStorageService = 'AzureFiles Standard'
param availability = 'AvailabilityZones'
param availabilityZones = [
  '1'
  '2'
  '3'
]
param avdConfigurationZipFileName = 'Configuration_1.0.02790.438.zip'
param avdObjectId = 'b4e1db8e-554e-46e7-b594-2410d928f601'
param deployActivityLogDiagnosticSetting = true
param deployDefender = true
param deployNetworkWatcherTrafficAnalytics = true
param deployPolicy = true
param desktopFriendlyName = 'desktop'
param diskSku = 'Premium_LRS'
param emailSecurityContact = 'brsteel@microsoft.com'
param enableAcceleratedNetworking = true
param enableApplicationInsights = true
param enableAvdInsights = true
param enableTelemetry = true
param environmentAbbreviation = 'dev'
param hostPoolPublicNetworkAccess = 'Enabled'
param hostPoolType = 'Pooled'
param hubVirtualNetworkResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/bws-rg-hub-network-va-dev/providers/Microsoft.Network/virtualNetworks/bws-vnet-hub-va-dev'
param identifier = 'cln'
param imageOffer = 'office-365'
param imagePublisher = 'MicrosoftWindowsDesktop'
param imageSku = 'win11-22h2-avd-m365'
param keyVaultDiagnosticsLogs = [
  {
    category: 'AuditEvent'
    enabled: true
  }
  {
    category: 'AzurePolicyEvaluationDetails'
    enabled: true
  }
]
param keyVaultDiagnosticMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]
param logAnalyticsWorkspaceRetention = 30
param logAnalyticsWorkspaceSku = 'PerGB2018'
param logStorageSkuName = 'Standard_GRS'
param networkInterfaceDiagnosticsMetrics = [
  {
    category: 'AllMetrics'
    enabled: true
  }
]
param networkSecurityGroupDiagnosticsLogs = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]
param networkWatcherFlowLogsRetentionDays = 30
param networkWatcherFlowLogsType = 'VirtualNetwork'
param networkWatcherResourceId = '/subscriptions/afb59830-1fc9-44c9-bba3-04f657483578/resourceGroups/bws-rg-hub-network-va-dev/providers/Microsoft.Network/networkWatchers/bws-nw-hub-va-dev'
param operationsLogAnalyticsWorkspaceResourceId = '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/bws-rg-operations-network-va-dev/providers/Microsoft.OperationalInsights/workspaces/bws-log-operations-va-dev'
param policy = 'NISTRev4'
param profile = 'Generic'
param sessionHostCount = 3
param sessionHostIndex = 0
param stampIndex = 0
param sharedServicesSubnetResourceId = '/subscriptions/3a8f043c-c15c-4a67-9410-a585a85f2109/resourceGroups/bws-rg-sharedServices-network-va-dev/providers/Microsoft.Network/virtualNetworks/bws-vnet-sharedServices-va-dev/subnets/bws-snet-sharedServices-va-dev'
param validationEnvironment = false
param virtualMachineAdminUsername = 'xadmin'
param virtualMachineAdminPassword = ''
param securityPrincipals = [
  {
    displayName: 'brsteel-avd-users'
    objectId: '07fbc372-4ad5-4bbb-847e-b19366b6bf9d'
  }
]
param privateLinkScopeResourceId = '/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/bws-rg-operations-network-va-dev/providers/microsoft.insights/privateLinkScopes/bws-pls-operations-va-dev'
param virtualMachineVirtualCpuCount = 2
param workspaceFriendlyName = 'workspace'
param workspacePublicNetworkAccess = 'Enabled'
param virtualNetworkAddressPrefixes = [
  '10.0.1${40 + (2 * stampIndex)}.0/23'
]
param subnetAddressPrefixes = [
  '10.0.1${40 + (2 * stampIndex)}.0/24'
  '10.0.1${41 + (2 * stampIndex)}.0/26'
]
param operationsVirtualNetworkAddressPrefix = '10.0.131.0/24'
param identityVirtualNetworkAddressPrefix = '10.0.130.0/24'
param enableWindowsUpdateFwRules = true
