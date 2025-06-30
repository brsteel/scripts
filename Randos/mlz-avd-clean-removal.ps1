<<<<<<< HEAD

[cmdletBinding()]
param (
    ## User input variables from the initial template spec deployment
    [Parameter(Mandatory=$false)]
    [string]$avdSubscriptionName = 'mlz-iac-tier3',
    [Parameter(Mandatory=$false)]
    [ValidateSet('va','az')]
    [string]$avdDeploymentLocation = 'va',
    [Parameter(Mandatory=$false)]
    [string]$avdDeploymentIdentifier = 'bws',
    [Parameter(Mandatory=$false)]
    [string]$avdDeploymentEnvironmentAbbreviation = 'test',
    [Parameter(Mandatory=$false)]
    [string]$avdStampIndex = '0',
    ## artifact storage account used to store the avd artifacts for the deployment
    [Parameter(Mandatory=$false)]
    [string]$avdArtifactsStorageAccountResourceId = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/bws-rg-network-operations-prod-va/providers/Microsoft.Storage/storageAccounts/bwsstopsprodva",
    ## is this the only avd deployment in the subscription?  more than one stamp?   more than one environment (dev, test, prod)? answer false.  otherwise, answer true.
    [Parameter(Mandatory=$false)]
    [bool]$onlyAvdDeployment = $false,
    [Parameter(Mandatory=$false)]
    [bool]$verifyonly = $true
)
$ErrorActionPreference = "SilentlyContinue"
if ($onlyAVDDeployment -eq $false) {
    Write-Host "Only AVD Deployment is set to false.  The script will NOT remove the global workspace and Windows Virtual Desktop role assignments."
} else {
    Write-Host "Only AVD Deployment is set to true.  The script will remove the global workspace and Windows Virtual Desktop role assignments."
=======
<#
.SYNOPSIS
   Script to remove AVD resources and associated role assignments from an AVD deployment.

.DESCRIPTION
  When the script runs, you will be prompted to login to a powershell session against the AVD subscription.
  The script will then proceed to delete the resources associated with the AVD deployment, and remove extraneous role assignments.
  There may be a Keyvault that may stick and not be deleted, this will need to be manually deleted, after the time period has passed, if it was used after the deployment.
  Depending on when the script is run, there may be errors in timing, causing errors to occur. If this happens, wait a few minutes and run the script again.
  Check the subscription(s) in the Azure portal to ensure all resource groups have been deleted, associated with the AVD stamp that was targeted.   
  If it is the final AVD deployment to be removed, the global workspace resource group and feed workspace group will be deleted. If it is not the final AVD deployment, the global workspace resource group will not be deleted.
  In particular, the script automates the removal of role assignments, recovery services vaults, and data collection rules, associated with the AVD deployment, which typically can prevent easy deletion of the AVD resource groups.
  The one item that cannot be removed is the keyvault.   If the stamp being deleted has been in use and the keyvault was used, it will have to be removed manually based on the time limit.

.PARAMETER azureEnvironment
    The Azure environment to connect to (e.g., AzureCloud, AzureUSGovernment, etc.).

.PARAMETER avdSubscriptionName
    The name of the Azure subscription where the AVD resources are deployed.

.PARAMETER mlzHubSubscriptionName
    The name of the Azure subscription where the management and network resources are deployed.

.PARAMETER avdIdentifier
    A unique identifier for the AVD deployment, used to name resources.

.PARAMETER avdStampIndex
    The index of the AVD stamp (e.g., 0 for the first stamp, 1 for the second stamp).

.PARAMETER avdDeploymentDesc
    A description of the AVD deployment (e.g., dev, prod).

.PARAMETER avdDeploymentLocation
    The location where the AVD deployment is hosted (e.g., va for Virginia).

.PARAMETER avdArtifactsResourceId
    The resource ID of the storage account that contains the AVD artifacts.

.PARAMETER finalAvdStamp
    Boolean flag to indicate if this is the final AVD stamp (true if final, false otherwise).

.EXAMPLE
    # Example 1: Connect to the default Azure environment and remove resources from the specified AVD subscription.
    . .\mls-avd-clean-removal.ps1 -azureEnvironment "AzureUSGovernment" -avdSubscriptionName "mlz-iac-tier3" -mlzHubSubscriptionName "mlz-iac-hub" -avdIdentifier "tst" -avdStampIndex "0" -avdDeploymentDesc "dev" -avdDeploymentLocation "va" -avdArtifactsResourceId "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Storage/storageAccounts/<storage account name>" -finalAvdStamp $false

    # This example connects to the Azure US Government environment and targets the AVD resources in the "mlz-iac-tier3" subscription.
    # It will process the resources based on the provided parameters, but since -finalAvdStamp is set to $false, it won't delete the global workspace resource group.

.EXAMPLE
    # Example 2: Connect to Azure and remove resources as part of the final AVD stamp.
    . .\mls-avd-clean-removal.ps1 -azureEnvironment "AzureUSGovernment" -avdSubscriptionName "mlz-iac-tier3" -mlzHubSubscriptionName "mlz-iac-hub" -avdIdentifier "tst" -avdStampIndex "0" -avdDeploymentDesc "dev" -avdDeploymentLocation "va" -avdArtifactsResourceId "/subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Storage/storageAccounts/<storage account name>" -finalAvdStamp $true

    # This example connects to the Azure public cloud environment and targets the AVD resources in the "mlz-iac-tier3" subscription.
    # With -finalAvdStamp set to $true, the script will also attempt to delete the global workspace resource group if found.

.NOTES
    Author:        Brooke Steele
    Email:         brsteel@microsoft.com
    Created:       August 19, 2024
    Modified:      August 19, 2024
    Version:       0.1
    Dependencies:  Azure PowerShell Az module latest version

.LINK
    https://aka.ms/missionlz/src/bicep/azure-virtual-desktop/utilities/mlz-avd-clean-removal.ps1

.REQUIREMENTS
    - Subscription owner permissions in the AVD and MLZ Hub subscriptions.
    - Global Administrator permissions in the Azure AD tenant, specifically to remove session host device accounts.
    - Azure PowerShell Az module installed on the machine running the script.
    - Correct naming conventions for AVD resources that were deployed as part of the MLZ AVD Addon deployment.
    - Microsoft.Graph module installed on the machine running the script. (e.g. "Install-Module Microsoft.Graph -Scope AllUsers -Repository PSGallery -Force")
    - Air gapped clouds have specific requirements for the Microsoft.Graph module.   Specifically, the application must be manually created in the Azure portal within the Tenant.

.TODO
    - add function to see if keyvault will prevent deletion of resource group that contains it and throw error to inform user to manually delete it after time period has passed.
    - it may be necessary to add section to remove device computer accounts for the stamp session hosts from Entra Id, so a repeated deployment can create new device accounts for the session hosts.
    - remove the avd artifact storage account and app id, once the add on removes the requirement to use it
#>

[cmdletbinding()]
  param (
    [Parameter(Mandatory = $true, HelpMessage = "The Azure environment to connect to (e.g., AzureCloud, AzureUSGovernment, etc.).")]
    [string]$azureEnvironment,

    [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure subscription where the AVD resources are deployed.")]
    [string]$avdSubscriptionName,

    [Parameter(Mandatory = $true, HelpMessage = "The name of the Azure subscription where the management and network resources are deployed.")]
    [string]$mlzHubSubscriptionName,

    [Parameter(Mandatory = $true, HelpMessage = "A unique identifier for the AVD deployment, used to name resources.")]
    [string]$avdIdentifier,

    [Parameter(Mandatory = $true, HelpMessage = "The index of the AVD stamp (e.g., 0 for the first stamp, 1 for the second stamp).")]
    [string]$avdStampIndex,

    [Parameter(Mandatory = $true, HelpMessage = "A description of the AVD deployment (e.g., dev, prod).")]
    [string]$avdDeploymentDesc,

    [Parameter(Mandatory = $true, HelpMessage = "The location where the AVD deployment is hosted (e.g., va for Virginia).")]
    [string]$avdDeploymentLocation,

    [Parameter(Mandatory = $true, HelpMessage = "The resource ID of the storage account that contains the AVD artifacts.")]
    [string]$avdArtifactsResourceId,

    [Parameter(Mandatory = $true, HelpMessage = "Boolean flag to indicate if this is the final AVD stamp (true if final, false otherwise).")]
    [bool]$finalAvdStamp = $false
)

$ErrorActionPreference = "SilentlyContinue"

#derive resource names
$avdControlPlaneRgName = "$avdIdentifier-$avdStampIndex-rg-controlPlane-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdHostsRgName = "$avdIdentifier-$avdStampIndex-rg-hosts-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdManagementRgName = "$avdIdentifier-$avdStampIndex-rg-management-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdNetworkRgName = "$avdIdentifier-$avdStampIndex-rg-network-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdFeedWorkspaceRgName = "$avdIdentifier-rg-feedWorkspace-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdGlobalWorkspaceRgName = "$avdIdentifier-rg-globalWorkspace-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdVnetName = "$avdIdentifier-$avdStampIndex-vnet-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdVmAgentDeployAppName = "Deploy VM Agents $avdIdentifier-$avdStampIndex-rg-network-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdDeployIdentityName = "$avdIdentifier-$avdStampIndex-id-deployment-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdArtifactsIdentityName = "$avdIdentifier-$avdStampIndex-id-artifacts-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdDcrName = "microsoft-avdi-$avdIdentifier-$avdStampIndex-dcr-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdKeyVaultNamePartialName = "$($avdIdentifier)$($avdStampIndex)kvavd$($avdDeploymentDesc)"
$avdRsvName = "$avdIdentifier-$avdStampIndex-rsv-avd-$avdDeploymentDesc-$avdDeploymentLocation"

## break down artifacts resource id
$avdArtifactResourceIdParts = $avdArtifactsResourceId.Split("/")
$avdArtifactsSubscriptionId = $avdArtifactResourceIdParts[2]
$avdArtifactsRgName = $avdArtifactResourceIdParts[4]
$avdArtifactsStorageAccountName = $avdArtifactResourceIdParts[8]
$avdArtifactsResourceGroupResourceId = "/subscriptions/$avdArtifactsSubscriptionId/resourceGroups/$avdArtifactsRgName"

#connect to azure avd subscription in a powershell session
$connected = Connect-AzAccount -Environment $azureEnvironment -Subscription $avdSubscriptionName
if (-not $connected) {
    Write-Error "Failed to connect to Azure"
>>>>>>> 6ee3bcdab726e0b36f39625145245edde347284f
}
else {
    Write-Host "Connected to Azure"

<<<<<<< HEAD
#$avdSubscriptionName = 'mlz-iac-tier3'
#$avdDeploymentIdentifier = 'pyt'
#$avdDeploymentEnvironmentAbbreviation = 'dev'
#$avdStampIndex = '0'
#$avdArtifactsStorageAccountResourceId = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/brook1-rg-network-operations-dev-va/providers/Microsoft.Storage/storageAccounts/brook1stopsdevva"
#$onlyAvdDeployment = $true
#$verifyonly = $true

#construct names from naming convention
$avdManagementResourceGroupName = $avdDeploymentIdentifier + '-'+ $avdStampIndex + '-rg-management-avd-' + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdNetworkResourceGroupName = $avdDeploymentIdentifier + '-'+ $avdStampIndex + '-rg-network-avd-' + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdHostResourceGroupName = $avdDeploymentIdentifier + '-'+ $avdStampIndex + '-rg-hosts-avd-' + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdControlPlaneResourceGroupName = $avdDeploymentIdentifier + '-'+ $avdStampIndex + '-rg-controlplane-avd-' + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdFeedWorkspaceResourceGroupName = $avdDeploymentIdentifier + '-rg-feedWorkspace-avd-' + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdDataCollectionRuleName = $avdDeploymentIdentifier + '-'+ $avdStampIndex + '-dcr-avd-' + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdGlobalWorkspacePartialName = '-rg-globalWorkspace-avd-' + $($avdDeploymentEnvironmentAbbreviation) + '-' + $avdDeploymentLocation
$avdDeploymentApplicationName = $avdDeploymentIdentifier + "-" + $avdStampIndex + "-id-deployment-avd-" + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdDeployVMAgentsAppName = "Deploy VM Agents " + $avdDeploymentIdentifier + "-" + $avdStampIndex + "-rg-network-avd-" + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdArtifactsApplicationName = $avdDeploymentIdentifier + "-" + $avdStampIndex + "-id-artifacts-avd-" + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdFsLogixStorageResourceGroupName = $avdDeploymentIdentifier + "-" + $avdStampIndex + "-rg-storage-avd-" + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
$avdAppName = "Windows Virtual Desktop"
$avdRsvName = $avdDeploymentIdentifier + "-" + $avdStampIndex + "-rsv-avd-" + $avdDeploymentEnvironmentAbbreviation + '-' + $avdDeploymentLocation
#identify artifact storage account subscription, resource group and name
$parts = $avdArtifactsStorageAccountResourceId -split '/'
$avdArtifactsStorageAccountSubscriptionId = $parts[2]
$avdArtifactsStorageAccountResourceGroupName = $parts[4]
#$avdArtifactsStorageAccountName = $parts[8]

## get subscription
$avdSubscriptionObject = Get-AzSubscription -SubscriptionName $avdSubscriptionName 
if (-not $avdSubscriptionObject) {
    Write-Output "Not Found: Subscription $avdSubscriptionName"
} else {
    Write-Output "Found: Subscription $($avdSubscriptionObject.Name)"
}

$avdArtifactsStorageAccountSubscriptionObject = Get-AzSubscription -SubscriptionId $avdArtifactsStorageAccountSubscriptionId
if (-not $avdArtifactsStorageAccountSubscriptionObject) {
    Write-Output "Not Found: Subscription $avdArtifactsStorageAccountSubscriptionId"
} else {
    Write-Output "Found: Subscription $($avdArtifactsStorageAccountSubscriptionObject.Name)"
}

## switch to the subscription where the avd deployment is located
Set-AzContext -SubscriptionObject $avdSubscriptionObject | Out-Null

## get resource groups  this can trigger detection of multiple stamp deployments and set onlyavddeployment to false
$avdFsLogixStorageResourceGroupObject = Get-AzResourceGroup -ResourceGroupName $avdFsLogixStorageResourceGroupName
if (-not $avdFsLogixStorageResourceGroupObject) {
    Write-Output "Not Found: FSLogix Storage resource group with name $avdFsLogixStorageResourceGroupName"
} else {
    Write-Output "Found: FSLogix Storage resource group named $($avdFsLogixStorageResourceGroupObject.ResourceGroupName)"
}

$avdGlobalWorkspaceResourceGroupObject = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -like "*$($avdGlobalWorkspacePartialName)*"} 
if (-not $avdGlobalWorkspaceResourceGroupObject) {
    Write-Output "Not Found: Global Workspace Resource group with partial name $avdGlobalWorkspacePartialName"
} else {
    Write-Output "Found: Global Workspace resource group named $($avdGlobalWorkspaceResourceGroupObject.ResourceGroupName)"
}

$avdNetworkResourceGroupObject = Get-AzResourceGroup -ResourceGroupName $avdNetworkResourceGroupName 
if (-not $avdNetworkResourceGroupObject) {
    Write-Output "Not Found: AVD Network resource group $avdNetworkResourceGroupName"
} else {
    Write-Output "Found: AVD Network resource group $($avdNetworkResourceGroupObject.ResourceGroupName)"
}

$avdManagementResourceGroupObject = Get-AzResourceGroup -ResourceGroupName $avdManagementResourceGroupName 
if (-not $avdManagementResourceGroupObject) {
    Write-Output "Not Found: AVD Management resource group $avdManagementResourceGroupName"
} else {
    Write-Output "Found: AVD Management resource group $($avdManagementResourceGroupObject.ResourceGroupName)"
}

$avdHostResourceGroupObject = Get-AzResourceGroup -ResourceGroupName $avdHostResourceGroupName 
if (-not $avdHostResourceGroupObject) {
    Write-Output "Not Found: AVD Host resource group $avdHostResourceGroupName"
} else {
    Write-Output "Found: AVD Host resource group $($avdHostResourceGroupObject.ResourceGroupName)"
}

$avdControlPlaneResourceGroupObject = Get-AzResourceGroup -ResourceGroupName $avdControlPlaneResourceGroupName 
if (-not $avdControlPlaneResourceGroupObject) {
    Write-Output "Not Found: AVD Control Plan resource group $avdControlPlaneResourceGroupName"
} else {
    Write-Output "Found: AVD Control Plane resource group $($avdControlPlaneResourceGroupObject.ResourceGroupName)"
}

$avdFeedWorkspaceResourceGroupObject = Get-AzResourceGroup -ResourceGroupName $avdFeedWorkspaceResourceGroupName 
if (-not $avdFeedWorkspaceResourceGroupObject) {
    Write-Output "Not Found: AVD Feed Workspace resource group $avdFeedWorkspaceResourceGroupName"
} else {
    Write-Output "Found: AVD Feed Workspace resource group $($avdFeedWorkspaceResourceGroupObject.ResourceGroupName)"
}

###### switch to subscription where the artifacts storage account is located
Set-AzContext -SubscriptionObject $avdArtifactsStorageAccountSubscriptionObject | Out-Null

$avdArtifactsStorageAccountResourceGroupObject = Get-AzResourceGroup -ResourceGroupName $avdArtifactsStorageAccountResourceGroupName
if (-not $avdArtifactsStorageAccountResourceGroupObject) {
    Write-Output "Not Found: Artifacts storage account resource group $avdArtifactsStorageAccountResourceGroupName"
} else {
    Write-Output "Found: Artifacts storage account resource group $($avdArtifactsStorageAccountResourceGroupObject.ResourceGroupName)"
}

###### switch back to the subscription where the avd deployment is located
Set-AzContext -SubscriptionObject $avdSubscriptionObject | Out-Null

## get resources that can prevent deletion of resource groups
$avdDataCollectionRuleObject = Get-AzDataCollectionRule -ResourceGroupName $avdManagementResourceGroupObject.ResourceGroupName -Name $avdDataCollectionRuleName
if (-not $avdDataCollectionRuleObject) {
    Write-Output "Not Found: Data collection rule $avdDataCollectionRuleName"
} else {
    Write-Output "Found: Data collection rule $($avdDataCollectionRuleObject.Name)"
}

if ($avdDataCollectionRuleObject) {
    $avdDcrAssociation = Get-AzDataCollectionRuleAssociation -ResourceGroupName $avdManagementResourceGroupObject.ResourceGroupName -DataCollectionRuleName $avdDataCollectionRuleObject.Name
    if (-not $avdDcrAssociation) {
        Write-Output "Not Found: Data collection rule association for $($avdDataCollectionRuleObject.Name)"
    } else {
        Write-Output "Found: Data collection rule association $($avdDcrAssociation.Name)"
    }
}

if ($avdRsvName) {
    $avdRsvObject = Get-AzRecoveryServicesVault -Name $avdRsvName
    if (-not $avdRsvObject) {
        Write-Output "Not Found: Recovery Services vault $($avdRsvObject.VaultName)"
    } else {
        Write-Output "Found: Recovery Services vault $($avdRsvObject.VaultName)"
    }
} 

$avdKeyvaultObject = Get-AzKeyVault -ResourceGroupName $avdNetworkResourceGroupObject.ResourceGroupName
if (-not $avdKeyvaultObject) {
    Write-Output "Not Found: Keyvault in $($avdNetworkResourceGroupObject.ResourceGroupName)"
} else {
    Write-Output "Found: Keyvault named $($avdKeyvaultObject.VaultName)"
}

#gather network information
$avdVnetObject = Get-AzVirtualNetwork -ResourceGroupName $avdNetworkResourceGroupName
if (-not $avdVnetObject) {
    Write-Output "Not Found: Virtual network $($avdVnetObject.Name) in $avdNetworkResourceGroupName"
} else {
    Write-Output "Found: Virtual network $($avdVnetObject.Name)"
}

$avdVnetPeeringObject = Get-AzVirtualNetworkPeering -VirtualNetwork $avdVnetObject.Name -ResourceGroupName $avdNetworkResourceGroupObject.ResourceGroupName
if (-not $avdVnetPeeringObject) {
    Write-Output "Not Found: Virtual network peering for $($avdVnetObject.Name) in $($avdNetworkResourceGroupObject.ResourceGroupName)"
} else {
    Write-Output "Found: $($avdVnetPeeringObject.Name) network peerings in $($avdVnetObject.Name)"
    $avdRemoteVnetPeering = $avdVnetPeeringObject.RemoteVirtualNetworkText | ConvertFrom-Json
    $parts = $avdRemoteVnetPeering.Id -split '/'
    $avdHubNetworkSubscriptionId = $parts[2]
    $avdHubNetworkResourceGroupName = $parts[4]
    $avdHubNetworkVnetName = $parts[8]
}

###### switch to subscription where the hub network is located
Set-AzContext -SubscriptionId $avdHubNetworkSubscriptionId | Out-Null

$avdHubNetworkResourceGroupObject = Get-AzResourceGroup -ResourceGroupName $avdHubNetworkResourceGroupName
if (-not $avdHubNetworkResourceGroupObject) {
    Write-Output "Not Found: Resource group $avdHubNetworkResourceGroupName"
} else {
    Write-Output "Found: Resource group $($avdHubNetworkResourceGroupObject.ResourceGroupName)"
}

$avdHubVnetObject = Get-AzVirtualNetwork -ResourceGroupName $avdHubNetworkResourceGroupObject.ResourceGroupName -Name $avdHubNetworkVnetName
if (-not $avdHubVnetObject) {
    Write-Output "Not Found: MLZ Hub birtual network $avdHubNetworkVnetName in $avdHubNetworkResourceGroupName"
} else {
    Write-Output "Found: MLZ Hub virtual network $($avdHubVnetObject.Name)"
}

$avdHubVnetPeeringObject = Get-AzVirtualNetworkPeering -VirtualNetworkName $avdHubVnetObject.Name -ResourceGroupName $avdHubNetworkResourceGroupObject.ResourceGroupName | Where-Object {$_.RemoteVirtualNetworkText -like "*$($avdVnetObject.Name)*"}
if (-not $avdHubVnetPeeringObject) {
    Write-Output "Not Found: Virtual network peering for $($avdHubVnetObject.Name) in $($avdHubNetworkResourceGroupObject.ResourceGroupName)"
} else {
    Write-Output "Found: $($avdHubVnetPeeringObject.Name) network peering in $($avdHubNetworkResourceGroupObject.ResourceGroupName)"
}

##### switch back to the subscription where the avd deployment is located
Set-AzContext -SubscriptionObject $avdSubscriptionObject | Out-Null

## get role assignments
## Deployment app
$avdDeploymentAppSPN = Get-AzADServicePrincipal -DisplayName $avdDeploymentApplicationName
if (-not $avdDeploymentAppSPN) {
    Write-Output "Not Found: Service principal $avdDeploymentApplicationName"
} else {
    Write-Output "Found: Service principal $($avdDeploymentAppSPN.DisplayName)"
}

$avdDeploymentAppRoleAssignmentsSub = Get-AzRoleAssignment -ObjectId $avdDeploymentAppSPN.Id
$avdDeploymentAppRoleAssignmentsRg  = Get-AzRoleAssignment -ObjectId $avdDeploymentAppSPN.Id -Scope "/subscriptions/$($avdArtifactsStorageAccountSubscriptionObject)/resourceGroups/$($avdArtifactsStorageAccountResourceGroupObject.ResourceGroupName)"
$avdDeploymentAppRoleAssignments = $($avdDeploymentAppRoleAssignmentsSub; $avdDeploymentAppRoleAssignmentsRg)
if (-not $avdDeploymentAppRoleAssignments) {
    Write-Output "Not Found: Role assignments for $($avdDeploymentAppSPN.DisplayName)"
} else {
    Write-Output "Found: $($avdDeploymentAppRoleAssignments.Count) role assignments for $($avdDeploymentAppSPN.DisplayName)"
}

## Agent Deployment App
$avdDeployVMAgentsAppSPN = Get-AzADServicePrincipal -DisplayName $avdDeployVMAgentsAppName
if (-not $avdDeployVMAgentsAppSPN) {
    Write-Output "Not Found: Service principal $avdDeployVMAgentsAppName"
} else {
    Write-Output "Found: Service principal $($avdDeployVMAgentsAppSPN.DisplayName)"
}

$avdDeployVMAgentRoleAssignmentsSub = Get-AzRoleAssignment -ObjectId $avdDeployVMAgentsAppSPN.Id
$avdDeployVMAgentRoleAssignmentsRg = Get-AzRoleAssignment -ObjectId $avdDeployVMAgentsAppSPN.Id -Scope "/subscriptions/$($avdArtifactsStorageAccountSubscriptionObject)/resourceGroups/$($avdArtifactsStorageAccountResourceGroupObject.ResourceGroupName)"
$avdDeployVMAgentRoleAssignments = $($avdDeployVMAgentRoleAssignmentsSub; $avdDeployVMAgentRoleAssignmentsRg)
if (-not $avdDeployVMAgentRoleAssignments) {
    Write-Output "Not Found: Role assignment for $($avdDeployVMAgentsAppSPN.DisplayName) on $($avdArtifactsStorageAccountResourceGroupObject.ResourceId)"
} else {
    Write-Output "Found: $($avdDeployVMAgentRoleAssignments.Count) role assignments for $($avdDeployVMAgentsAppSPN.DisplayName)"
}

## Windows Virtual Desktop 1st Party app
$avdAppSPN = Get-AzADServicePrincipal -DisplayName $avdAppName
if (-not $avdAppSPN) {
    Write-Output "Not Found: Service principal $avdAppName"
} else {
    Write-Output "Found: Service principal $($avdAppSPN.DisplayName)"
}

$avdAppRoleAssignments = Get-AzRoleAssignment -ObjectId $avdAppSPN.Id
if (-not $avdAppRoleAssignments) {
    Write-Output "Not Found: Role assignment for $($avdAppSPN.DisplayName)"
} else {
    Write-Output "Found: $($avdAppRoleAssignment.Count) for $($avdAppSPN.DisplayName)."
}

## Artifacts app
$avdArtifactsAppSPN = Get-AzADServicePrincipal -DisplayName $avdArtifactsApplicationName
if (-not $avdArtifactsAppSPN) {
    Write-Output "Not Found: Service principal $avdArtifactsApplicationName"
} else {
    Write-Output "Found: Service principal $($avdArtifactsAppSPN.DisplayName)"
}

$avdArtifactsAppRoleAssignments = Get-AzRoleAssignment -ObjectId $avdArtifactsAppSPN.Id -Scope $avdArtifactsStorageAccountResourceId
if (-not $avdArtifactsAppRoleAssignments) {
    Write-Output "Not Found: Role assignment for $($avdArtifactsAppSPN.DisplayName) on $avdArtifactsStorageAccountResourceId"
} else {
    Write-Output "Found: $($avdArtifactsAppRoleAssignments.Count) role assignments for $($avdArtifactsAppSPN.DisplayName)"
}

if ($verifyonly -eq $false) {
    #### REMOVE RESOURCE ASSIGNMENTS
    # Check if the avd application role assignment is on the subscription if this is the only avd deployment in the subscription
    if ($onlyAvdDeployment -eq $true) {
        if ($avdAppRoleAssignments) {
        #    Write-Output "Only AVD Deployment set to true, removing Windows Virtual Desktop application role assignment from the subscription named $($avdSubscriptionObject.Name)"
        #    Remove-AzRoleAssignment -ObjectId $avdAppSPN.Id -RoleDefinitionName "Desktop Virtualization Power On Contributor" -Scope "/subscriptions/$($avdSubscriptionObject.Id)"
        #    $avdAppRoleAssignment = $null
            foreach ($assignment in $avdAppRoleAssignments) {
                Write-Output "Removing $($assignment.RoleDefinitionName) role assignment from $($assignment.Scope) for $($avdAppSPN.DisplayName)"
                Remove-AzRoleAssignment -ObjectId $avdAppSPN.Id -RoleDefinitionName $assignment.RoleDefinitionName -Scope $assignment.Scope
            }   
        }
    }
    # Remove deployment managed identity from the resource group where the artifacts storage account is located and from the avd subscription
    if ($avdDeploymentAppRoleAssignments) {
        foreach ($assignment in $avdDeploymentAppRoleAssignments) {
            Write-Output "Removing $($assignment.RoleDefinitionName) role assignment from $($assignment.Scope) for $($avdDeploymentAppSPN.DisplayName)"
            Remove-AzRoleAssignment -ObjectId $avdDeploymentAppSPN.Id -RoleDefinitionName $assignment.RoleDefinitionName -Scope $assignment.Scope
        }
        $avdDeploymentAppSPN = $null
    } 
    
    Write-Output "Removing Log Analytics Contributor role assignment from the artifacts storage account resource group"
    
    
    if ($avdDeployVMAgentsAppSPN) {
        foreach ($assignment in $avdDeployVMAgentRoleAssignments) {
            Write-Output "Removing $($assignment.RoleDefinitionName) role assignment from $($assignment.Scope) for $($avdDeployVMAgentsAppSPN.DisplayName)"
            Remove-AzRoleAssignment -ObjectId $avdDeployVMAgentsAppSPN.Id -RoleDefinitionName $assignment.RoleDefinitionName -Scope $assignment.Scope
        }
        $avdDeployVMAgentsAppSPN = $null
    }

    if ($avdArtifactsAppRoleAssignments) {
    #    Write-Output "Removing Storage Blob Data Reader role assignment from the artifacts storage account resource group for $($avdArtifactsAppSPN.DisplayName)"
    #    Remove-AzRoleAssignment -ObjectId $avdArtifactsAppSPN.Id -RoleDefinitionName "Storage Blob Data Reader" -Scope "$avdArtifactsStorageAccountResourceId"
    #    $avdArtifactsAppRoleAssignment = $null
        foreach ($assignment in $avdArtifactsAppRoleAssignments) {
            Write-Output "Removing $($assignment.RoleDefinitionName) role assignment from $($assignment.Scope) for $($avdArtifactsAppSPN.DisplayName)"
            Remove-AzRoleAssignment -ObjectId $avdArtifactsAppSPN.Id -RoleDefinitionName $assignment.RoleDefinitionName -Scope $assignment.Scope
        }
        $avdArtifactsAppSPN = $null
    }

    ##### REMOVE RESOURCES THAT CAN PREVENT DELETION OF RESOURCE GROUPS
    if ($avdDcrAssociation) {
        foreach ($association in $avdDcrAssociation) {
            $segment = "/providers/microsoft.insights/datacollectionruleassociations/"
            $resourceUri = $association.Id -replace "$segment.*"
            Write-Output "Removing data collection rule association $($association.Name) from $resourceUri"
            Remove-AzDataCollectionRuleAssociation -AssociationName $association.Name -ResourceUri $resourceUri
        }
    }

    if ($avdDataCollectionRuleObject) {
        Write-Output "Removing data collection rule $($avdDataCollectionRuleObject.Name) from $($avdManagementResourceGroupObject.ResourceGroupName)"
        Remove-AzDataCollectionRule -ResourceGroupName $avdManagementResourceGroupObject.ResourceGroupName -Name $avdDataCollectionRuleObject.Name
        $avdDataCollectionRuleObject = $null
    }

    if ($avdKeyvaultObject) {
        Write-Output "Removing key vault $($avdKeyvaultObject.VaultName) from $($avdKeyvaultObject.ResourceGroupName)"
        Remove-AzKeyVault -VaultName $avdKeyvaultObject.VaultName -ResourceGroupName $avdKeyvaultObject.ResourceGroupName -Force
        $avdKeyvaultObject = $null
    }

    if ($avdRsvObject) {
        Set-AzRecoveryServicesAsrVaultContext -Vault $avdRsvObject
        Write-Output "Disabling soft delete for the Azure Backup Recovery Services vault $($avdRsvObject.VaultName)"
        Set-AzRecoveryServicesVaultProperty -VaultId $avdRsvObject.Id -SoftDeleteFeatureState Disable

        Write-Output "Soft delete disabled for the vault" $avdRsvObject.VaultName
        $containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $avdRsvObject.Id | Where-Object {$_.DeleteState -eq "ToBeDeleted"} #fetch backup items in soft delete state
        foreach ($softitem in $containerSoftDelete)
        {
            Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $avdRsvObject.Id -Force #undelete items in soft delete state
        }

        ## Check if there are backup items in a soft-deleted state and reverse the delete operation
        $backupItemsVM = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $avdRsvObject.Id
        foreach($item in $backupItemsVM) {
            Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $avdRsvObject.Id -RemoveRecoveryPoints -Force #stop backup and delete Azure VM backup items
        }

        ## Delete the Recovery Services vault 
        Write-Output "Removing Recovery Services vault $avdRsvName"
        Remove-AzRecoveryServicesVault -VaultId $avdRsvObject.Id -Verbose
        $avdRsvObject = $null
    }

    ## Remove network peering
    if ($avdVnetPeeringObject) { 
        Write-Output "Removing network peering $($avdVnetPeeringObject.Name) from $($avdVnetObject.Name) in $($avdNetworkResourceGroupObject.ResourceGroupName)"
        Remove-AzVirtualNetworkPeering -Name $avdVnetPeeringObject.Name -ResourceGroupName $avdNetworkResourceGroupObject.ResourceGroupName -VirtualNetwork $avdVnetObject.Name -Force
        $avdVnetPeeringObject = $null
    }

    ###### switch to subscription where the hub network is located
    Set-AzContext -SubscriptionId $avdHubNetworkSubscriptionId | Out-Null
    if ($avdHubVnetPeeringObject) {
        Write-Output "Removing network peering $($avdHubVnetPeeringObject.Name) from $($avdHubVnetObject.Name) in $($avdHubNetworkResourceGroupObject.ResourceGroupName) resource group"
        Remove-AzVirtualNetworkPeering -Name $avdHubVnetPeeringObject.Name -ResourceGroupName $avdHubNetworkResourceGroupObject.ResourceGroupName -VirtualNetworkName $avdHubVnetObject.Name -Force
        $avdHubVnetPeeringObject = $null
    }

    ###### switch back to the subscription where the avd deployment is located
    Set-AzContext -SubscriptionObject $avdSubscriptionObject | Out-Null

    # remove avd deployment resource groups from the subscription, only remove global workspace if it is the only avd deployment in the subscription
    if ($avdFsLogixStorageResourceGroupObject) {
        Write-Output "Removing resource group $($avdFsLogixStorageResourceGroupObject.ResourceGroupName)"
        $avdFsLogixStorageResourceGroupObject | Remove-AzResourceGroup -Force
        $avdFsLogixStorageResourceGroupObject = $null
    }

    if ($avdManagementResourceGroupObject) {
        Write-Output "Removing resource group $($avdManagementResourceGroupObject.ResourceGroupName)"
        $avdManagementResourceGroupObject | Remove-AzResourceGroup -Force
        $avdManagementResourceGroupObject = $null
    }

    if ($avdControlPlaneResourceGroupObject) {
        Write-Output "Removing resource group $($avdControlPlaneResourceGroupObject.ResourceGroupName)"
        $avdControlPlaneResourceGroupObject | Remove-AzResourceGroup -Force
        $avdControlPlaneResourceGroupObject = $null
    }

    if ($avdHostResourceGroupObject) {
        Write-Output "Removing resource group $($avdHostResourceGroupObject.ResourceGroupName)"
        $avdHostResourceGroupObject | Remove-AzResourceGroup -Force
        $avdHostResourceGroupObject = $null
    }

    if ($avdFeedWorkspaceResourceGroupObject) {
        Write-Output "Removing resource group $($avdFeedWorkspaceResourceGroupObject.ResourceGroupName)"
        $avdFeedWorkspaceResourceGroupObject | Remove-AzResourceGroup -Force
        $avdFeedWorkspaceResourceGroupObject = $null
    }

    if ($avdNetworkResourceGroupObject) {
        Write-Output "Removing resource group $($avdNetworkResourceGroupObject.ResourceGroupName)"
        $avdNetworkResourceGroupObject | Remove-AzResourceGroup -Force
        $avdNetworkResourceGroupObject = $null
    }

    if ($onlyAvdDeployment -eq $true) {
        if ($avdGlobalWorkspaceResourceGroupObject) {
            Write-Output "This is the only avd deployment in the subscription.  Removing the global workspace resource group $($avdGlobalWorkspaceResourceGroupObject.ResourceGroupName)"
            $avdGlobalWorkspaceResourceGroupObject | Remove-AzResourceGroup -Force
            $avdGlobalWorkspaceResourceGroupObject = $null
            }
        }
    }
=======
    $avdSubscriptionId = (Get-AzSubscription -SubscriptionName $avdSubscriptionName).Id
    $azureManagementEndpointUrl = (Get-AzEnvironment -Name $azureEnvironment).ResourceManagerUrl

    #find global workspace rg
    $subscriptionList = Get-AzSubscription 
    Foreach ($subscription in $subscriptionList){
        Select-AzSubscription -SubscriptionId $subscription.Id    
        $avdGlobalWorkspaceRgObj = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -like "*$avdGlobalWorkspaceRgName*"}
        If ($avdGlobalWorkspaceRgObj -ne $null){
            $avdGlobalWorkspaceRgSubscriptionId = $subscription.Id
            Write-Host "Global Workspace Resource Group named: $avdGlobalWorkspaceRgObj found in subscription named:" $subscription.Name
            break
        }
    }

  #function to remove role assignments
  function Remove-RoleAssignment {
  param (
    $ObjectId,
    $SubscriptionId
  )

  Select-AzSubscription $SubscriptionId
  $roleAssignment = Get-AzRoleAssignment -ObjectId $objectId | Remove-AzRoleAssignment
    }

  #function to remove data collection rules
  function Remove-Dcr {
  param (
    $DcrName,
    $ResourceGroup,
    $SubscriptionId
  )

  Select-AzSubscription $SubscriptionId
  $dcrToDelete = Get-AzDataCollectionRule -Name $dcrName -ResourceGroupName $ResourceGroup
  $dcrAssociations = Get-AzDataCollectionRuleAssociation -DataCollectionRuleName $DcrToDelete.name -ResourceGroupName $ResourceGroup
  foreach ($dcrAssociation in $dcrAssociations){
    $resourceUri = $dcrAssociation.Id -replace "/providers/microsoft.insights/datacollectionruleassociations/$($dcrAssociation.name)", ""
    Remove-AzDataCollectionRuleAssociation -AssociationName $dcrAssociation.Name -ResourceUri $resourceUri
  }
  Remove-AzDataCollectionRule -DataCollectionRuleName $DcrToDelete.Name -ResourceGroupName $ResourceGroup
  #Finish
    }

  #function to remove recovery services vaults
  function Remove-Rsv {
    param (
      $VaultName,
      $Subscription,
      $ResourceGroup,
      $SubscriptionId,
      $AzureManagementEndpointUrl
    )
  
    Select-AzSubscription $SubscriptionId
    $VaultToDelete = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroup
    Set-AzRecoveryServicesAsrVaultContext -Vault $VaultToDelete
    
    Set-AzRecoveryServicesVaultProperty -Vault $VaultToDelete.ID -SoftDeleteFeatureState Disable #disable soft delete
    Write-Host "Soft delete disabled for the vault" $VaultName
    $containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID | Where-Object {$_.DeleteState -eq "ToBeDeleted"} #fetch backup items in soft delete state
    foreach ($softitem in $containerSoftDelete)
      {
          Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $VaultToDelete.ID -Force #undelete items in soft delete state
      }
    
    #Fetch all protected items and servers
    $backupItemsVM = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID
    $StorageAccounts = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -VaultId $VaultToDelete.ID
    $pvtendpoints = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $VaultToDelete.ID
    
    foreach($item in $backupItemsVM)
        {
            Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force #stop backup and delete Azure VM backup items
        }
    Write-Host "Disabled and deleted Azure VM backup items"
      
    foreach($item in $StorageAccounts)
        {
            Unregister-AzRecoveryServicesBackupContainer -container $item -Force -VaultId $VaultToDelete.ID #unregister storage accounts
        }
    Write-Host "Unregistered Storage Accounts"
  
    foreach($item in $pvtendpoints)
      {
        $penamesplit = $item.Name.Split(".")
        $pename = $penamesplit[0]
        Remove-AzPrivateEndpointConnection -ResourceId $item.Id -Force #remove private endpoint connections
        Remove-AzPrivateEndpoint -Name $pename -ResourceGroupName $ResourceGroup -Force #remove private endpoints
      }
    Write-Host "Removed Private Endpoints"
  
    #Recheck presence of backup items in vault
    $backupItemsVMFin = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID
    $StorageAccountsFin = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -VaultId $VaultToDelete.ID
    $pvtendpointsFin = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $VaultToDelete.ID
    
    #Display items which are still present in the vault and might be preventing vault deletion.
    if($backupItemsVMFin.count -ne 0) 
    {
      Write-Host $backupItemsVMFin.count "Azure VM backups are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red
    }
    if($StorageAccountsFin.count -ne 0) 
    {
      Write-Host $StorageAccountsFin.count "Storage Accounts are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red
    }
    if($pvtendpointsFin.count -ne 0) 
    {
      Write-Host $pvtendpointsFin.count "Private endpoints are still linked to the vault. Remove the same for successful vault deletion." -ForegroundColor Red
    }
    
    $accesstoken = Get-AzAccessToken
    $token = $accesstoken.Token
    $authHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token
    }
    $restUri = "$azureManagementEndpointUrl" + "subscriptions/"+ $SubscriptionId + "/resourcegroups/" + $ResourceGroup + "/providers/Microsoft.RecoveryServices/vaults/" + $VaultName + "?api-version=2021-06-01&operation=DeleteVaultUsingPS"
    $response = Invoke-RestMethod -Uri $restUri -Headers $authHeader -Method DELETE
    
    $VaultDeleted = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroup -erroraction 'silentlycontinue'
    if ($VaultDeleted -eq $null)
      {
      Write-Host "Recovery Services Vault" $VaultName "successfully deleted"
      }
    #Finish
  }
  
  Write-Host "Moving to the AVD Subscription named: $avdSubscriptionName"
  Select-AzSubscription $avdSubscriptionId
  
  Write-Host "Looking for an Azure Recovery Services Vault named: $avdRsvName in the Resource Group named: $avdManagementRgName. If found, it will be deleted."
  $rsv = Get-AzRecoveryServicesVault -Name $avdRsvName -ResourceGroupName $avdManagementRgName -ErrorAction 'silentlycontinue'
  if ($rsv -ne $null)
  {
    Remove-Rsv -VaultName $avdRsvName -ResourceGroup $avdManagementRgName -SubscriptionId $avdSubscriptionId -AzureManagementEndpointUrl $azureManagementEndpointUrl
  }
  
  Write-Host "Looking for a Data Collection Rule named: $avdDcrName in the Resource Group named: $avdManagementRgName. If found, it will be deleted."
  $dcr = $dcrToDelete = Get-AzDataCollectionRule -Name $avdDcrName -ResourceGroupName $avdManagementRgName -ErrorAction 'silentlycontinue'
  if ($dcr -ne $null)
  {
    Remove-Dcr -DcrName $avdDcrName -ResourceGroup $avdManagementRgName -SubscriptionId $avdSubscriptionId
  }
  Write-Host "Looking for a Key Vault named: $avdKeyVaultNamePartialName in the Resource Group named: $avdManagementRgName. If found, it will be deleted."
  #PUT DELETING KEYVAULT CODE HERE
  
  Write-Host "Removing role assignments for the AVD deployment identity, AVD VM Agent Deploy application, and the AVD artifacts identity."
  $avdDeployIdentity = Get-AzADServicePrincipal -DisplayName $avdDeployIdentityName
  Remove-RoleAssignment -ObjectId $avdDeployIdentity.Id -SubscriptionId $avdArtifactsSubscriptionId
  Remove-RoleAssignment -ObjectId $avdDeployIdentity.Id -SubscriptionId $avdSubscriptionId
  $avdVmDeployAgentsApp = Get-AzAdServicePrincipal -DisplayName $avdVmAgentDeployAppName
  Remove-RoleAssignment -ObjectId $avdVmDeployAgentsApp.Id -SubscriptionId $avdArtifactsSubscriptionId
  $avdArtifactsIdentity = Get-AzADServicePrincipal -DisplayName $avdArtifactsIdentityName
  Remove-RoleAssignment -ObjectId $avdArtifactsIdentity.Id -SubscriptionId $avdArtifactsSubscriptionId
  
  Write-Host "Changing foces back to the AVD Subscription named: $avdSubscriptionName"
  Select-AzSubscription $avdSubscriptionId
  
  Write-Host "Getting the netwwork peering information from the AVD VNet named: $avdVnetName"
  $avdVnetPeering = Get-AzVirtualNetworkPeering -ResourceGroupName $avdNetworkRgName -VirtualNetworkName $avdVnetName
  $avdRemotePeerResourceId = ($avdVnetPeering.RemoteVirtualNetworkText | ConvertFrom-Json).Id
  #break down remote peer resource id
  $avdRemotePeerResourceIdParts = $avdRemotePeerResourceId.Split("/")
  $avdRemotePeerSubscriptionId = $avdRemotePeerResourceIdParts[2]
  $avdRemotePeerRgName = $avdRemotePeerResourceIdParts[4]
  $avdRemotePeerVnetName = $avdRemotePeerResourceIdParts[8]
  
  Write-Host "Connecting to the subscription that contains the peered hub connection."
  Select-AzSubscription -SubscriptionId $avdRemotePeerSubscriptionId
  
  Write-Host "Removing the peering connection from the remote peer VNet named: $avdRemotePeerVnetName to the AVD VNet named: $avdVnetName"
  $avdRemotePeering = Get-AzVirtualNetworkPeering -ResourceGroupName $avdRemotePeerRgName -VirtualNetworkName $avdRemotePeerVnetName
  foreach ($peering in $avdRemotePeering){
      if ($peering.Name -like "to-$avdVnetName"){
          Remove-AzVirtualNetworkPeering -ResourceGroupName $avdRemotePeerRgName -VirtualNetworkName $avdRemotePeerVnetName -Name $peering.Name -Force
      }
  }
  
  Write-Host "Changing back to the AVD Subscription named: $avdSubscriptionName"
  Select-AzSubscription -SubscriptionId $avdSubscriptionId
  Write-Host "Removing the Resource Groups"
  $avdRgList = @($avdControlPlaneRgName, $avdManagementRgName, $avdGlobalWorkspaceRgName, $avdFeedWorkspaceRgName, $avdHostsRgName, $avdNetworkRgName)
  foreach ($rg in $avdRgList){
      if ($rg -ne $avdGlobalWorkspaceRgName -or $rg -ne $avdFeedWorkspaceRgName){
        Select-AzSubscription -SubscriptionId $avdSubscriptionId
        Remove-AzResourceGroup -Name $rg -Force
      }
      else {
        if ($finalAvdStamp -eq $true){
          if ($rg -eq "$avdGlobalWorkspaceRgName"){
            Select-AzSubscription -SubscriptionId $avdGlobalWorkspaceRgSubscriptionId
            Remove-AzResourceGroup -Name $rg -Force
          }
          else {
            Remove-AzResourceGroup -Name $rg -Force
          }
        }
        else {
          Write-Host "This is not the final AVD stamp. The global workspace resource group and feed workspace group will not be deleted."
        }
        }
    }
}
>>>>>>> 6ee3bcdab726e0b36f39625145245edde347284f
