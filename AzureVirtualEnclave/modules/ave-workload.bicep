@description('The Azure region where resources will be deployed')
param location string

@description('Name of the workload')
param workloadName string

@description('Parent Virtual Enclave name')
param parentEnclaveName string

@description('Tags to apply to all resources')
param tags object

@description('Workload configuration settings')
param workloadConfig object

// Fallback RBAC arrays (effective enclave-level arrays provided by enclave module)
@description('Effective workload Contributors (fallback if workloadConfig.rbac.contributors empty)')
param workloadContributors array = []
@description('Effective workload Readers')
param workloadReaders array = []
@description('Effective workload Network Contributors')
param workloadNetworkContributors array = []
@description('Effective workload Monitoring Readers')
param workloadMonitoringReaders array = []
@description('Effective workload Monitoring Contributors')
param workloadMonitoringContributors array = []
@description('Effective workload Log Analytics Readers')
param workloadLogAnalyticsReaders array = []
@description('Effective workload Log Analytics Contributors')
param workloadLogAnalyticsContributors array = []
@description('Effective workload Security Readers')
param workloadSecurityReaders array = []
@description('Effective workload Security Admins')
param workloadSecurityAdmins array = []
@description('Effective workload User Access Administrators')
param workloadUserAccessAdministrators array = []

// Reference the parent virtual enclave
resource parentEnclave 'Microsoft.Mission/virtualEnclaves@2025-05-01-preview' existing = {
  name: parentEnclaveName
}

// Normalize resourceGroupCollection entries to full ARM IDs if user supplied bare RG names
var workloadResourceGroupIds = [for rg in (workloadConfig.?resourceGroupCollection ?? []): (startsWith(rg, '/subscriptions/') || startsWith(rg, '/providers/')) ? rg : '/subscriptions/${subscription().subscriptionId}/resourceGroups/${rg}']

// Deploy AVE Workload as a child resource of the virtual enclave
// Workloads are container objects that will contain resources when deployed
resource workload 'Microsoft.Mission/virtualEnclaves/workloads@2025-05-01-preview' = {
  name: workloadName
  parent: parentEnclave
  location: location
  tags: tags
  properties: {
    resourceGroupCollection: workloadResourceGroupIds
  }
}

// Determine effective per-workload RBAC arrays (clearable inheritance: presence of property = override even if empty)
var effContributors = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'contributors') ? (workloadConfig.rbac.contributors ?? []) : workloadContributors
var effReaders = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'readers') ? (workloadConfig.rbac.readers ?? []) : workloadReaders
var effNetworkContributors = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'networkContributors') ? (workloadConfig.rbac.networkContributors ?? []) : workloadNetworkContributors
var effMonitoringReaders = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'monitoringReaders') ? (workloadConfig.rbac.monitoringReaders ?? []) : workloadMonitoringReaders
var effMonitoringContributors = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'monitoringContributors') ? (workloadConfig.rbac.monitoringContributors ?? []) : workloadMonitoringContributors
var effLogReaders = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'logReaders') ? (workloadConfig.rbac.logReaders ?? []) : workloadLogAnalyticsReaders
var effLogContributors = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'logContributors') ? (workloadConfig.rbac.logContributors ?? []) : workloadLogAnalyticsContributors
var effSecurityReaders = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'securityReaders') ? (workloadConfig.rbac.securityReaders ?? []) : workloadSecurityReaders
var effSecurityAdmins = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'securityAdmins') ? (workloadConfig.rbac.securityAdmins ?? []) : workloadSecurityAdmins
var effUserAccessAdmins = contains(workloadConfig, 'rbac') && contains(workloadConfig.rbac, 'userAccessAdministrators') ? (workloadConfig.rbac.userAccessAdministrators ?? []) : workloadUserAccessAdministrators

// Role definitions
var rdContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','b24988ac-6180-42a0-ab88-20f7382dd24c')
var rdReader = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','acdd72a7-3385-48ef-bd42-f606fba81ae7')
var rdNetworkContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','4d97b98b-1d4f-4787-a291-c67834d212e7')
var rdMonitoringReader = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','43d0d8ad-25c7-4714-9337-8ba259a9fe05')
var rdMonitoringContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','749f88d5-cbae-40b8-bcfc-e573ddc772fa')
var rdLogReader = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','73c42c96-874c-492b-b04d-ab87d138a893')
var rdLogContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','92aaf0da-9dab-42b6-94a3-d43ce8d16293')
var rdSecurityReader = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','8d32ff11-19e7-4f25-8d7a-4176c81c0f83')
var rdSecurityAdmin = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','fb1c8493-542b-48eb-b624-b4c8fea62acd')
var rdUserAccessAdmin = subscriptionResourceId('Microsoft.Authorization/roleDefinitions','18d7d88d-d35e-4fb5-a5c3-7773a3e3d1af')

// Workload-scope roleAssignments
resource workloadContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effContributors: {
  name: guid(workload.id, rdContributor, p)
  scope: workload
  properties: {
    roleDefinitionId: rdContributor
    principalId: p
  }
}]
resource workloadReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effReaders: {
  name: guid(workload.id, rdReader, p)
  scope: workload
  properties: {
    roleDefinitionId: rdReader
    principalId: p
  }
}]
resource workloadNetworkContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effNetworkContributors: {
  name: guid(workload.id, rdNetworkContributor, p)
  scope: workload
  properties: {
    roleDefinitionId: rdNetworkContributor
    principalId: p
  }
}]
resource workloadMonitoringReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effMonitoringReaders: {
  name: guid(workload.id, rdMonitoringReader, p)
  scope: workload
  properties: {
    roleDefinitionId: rdMonitoringReader
    principalId: p
  }
}]
resource workloadMonitoringContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effMonitoringContributors: {
  name: guid(workload.id, rdMonitoringContributor, p)
  scope: workload
  properties: {
    roleDefinitionId: rdMonitoringContributor
    principalId: p
  }
}]
resource workloadLogReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effLogReaders: {
  name: guid(workload.id, rdLogReader, p)
  scope: workload
  properties: {
    roleDefinitionId: rdLogReader
    principalId: p
  }
}]
resource workloadLogContributorAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effLogContributors: {
  name: guid(workload.id, rdLogContributor, p)
  scope: workload
  properties: {
    roleDefinitionId: rdLogContributor
    principalId: p
  }
}]
resource workloadSecurityReaderAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effSecurityReaders: {
  name: guid(workload.id, rdSecurityReader, p)
  scope: workload
  properties: {
    roleDefinitionId: rdSecurityReader
    principalId: p
  }
}]
resource workloadSecurityAdminAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effSecurityAdmins: {
  name: guid(workload.id, rdSecurityAdmin, p)
  scope: workload
  properties: {
    roleDefinitionId: rdSecurityAdmin
    principalId: p
  }
}]
resource workloadUserAccessAdminAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for p in effUserAccessAdmins: {
  name: guid(workload.id, rdUserAccessAdmin, p)
  scope: workload
  properties: {
    roleDefinitionId: rdUserAccessAdmin
    principalId: p
  }
}]

// Outputs
output workloadName string = workload.name
output workloadResourceId string = workload.id
output provisioningState string = workload.properties.provisioningState
output resourceGroupCollection array = workload.properties.resourceGroupCollection
output workloadRbacEffective object = {
  contributors: effContributors
  readers: effReaders
  networkContributors: effNetworkContributors
  monitoringReaders: effMonitoringReaders
  monitoringContributors: effMonitoringContributors
  logReaders: effLogReaders
  logContributors: effLogContributors
  securityReaders: effSecurityReaders
  securityAdmins: effSecurityAdmins
  userAccessAdministrators: effUserAccessAdmins
}
