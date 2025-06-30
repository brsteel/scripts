
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
}

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