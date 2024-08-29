[cmdletbinding()]
param (
    [string]$azureEnvironment = "AzureUSGovernment",
    [string]$avdSubscriptionName = "mlz-iac-tier3",
    [string]$mlzHubSubscriptionName = "mlz-iac-hub",
    [string]$avdIdentifier = "bws",
    [string]$avdStampIndex = "0",
    [string]$avdDeploymentDesc = "dev",
    [string]$avdDeploymentLocation = "va",
    [string]$avdArtifactsResourceId = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/bws-rg-network-operations-prod-va/providers/Microsoft.Storage/storageAccounts/bwsstopsprodva",
    [bool]$finalAvdStamp = $false
)

#$azureEnvironment = "AzureUSGovernment"
#$avdSubscriptionName = "mlz-iac-tier3"
#$mlzHubSubscriptionName = "mlz-iac-hub"
#$avdIdentifier = "bws"
#$avdStampIndex = "0"
#$avdDeploymentDesc = "dev"
#$avdDeploymentLocation = "va"
#$avdArtifactsResourceId = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/bws-rg-network-operations-prod-va/providers/Microsoft.Storage/storageAccounts/bwsstopsprodva"
#$finalAvdStamp = $false

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
$avdDcrName = "$avdIdentifier-$avdStampIndex-dcr-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdKeyVaultNamePartialName = "$($avdIdentifier)$($avdStampIndex)kvavd$($avdDeploymentDesc)"
$avdRsvName = "$avdIdentifier-$avdStampIndex-rsv-avd-$avdDeploymentDesc-$avdDeploymentLocation"
$avdDcrName = "$avdIdentifier-$avdStampIndex-dcr-avd-$avdDeploymentDesc-$avdDeploymentLocation"

## break down artifacts resource id
$avdArtifactResourceIdParts = $avdArtifactsResourceId.Split("/")
$avdArtifactsSubscriptionId = $avdArtifactResourceIdParts[2]
$avdArtifactsRgName = $avdArtifactResourceIdParts[4]
$avdArtifactsStorageAccountName = $avdArtifactResourceIdParts[8]
$avdArtifactsResourceGroupResourceId = "/subscriptions/$avdArtifactsSubscriptionId/resourceGroups/$avdArtifactsRgName"

$connected = Connect-AzAccount -Environment $azureEnvironment -Subscription $avdSubscriptionName
if (-not $connected) {
    Write-Error "Failed to connect to Azure"
}
else {
    Write-Host "Connected to Azure"

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

    function Remove-RoleAssignment {
  param (
    $ObjectId,
    $SubscriptionId
  )

  Select-AzSubscription $SubscriptionId
  $roleAssignment = Get-AzRoleAssignment -ObjectId $objectId | Remove-AzRoleAssignment
    }

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
  if($backupItemsVMFin.count -ne 0) {Write-Host $backupItemsVMFin.count "Azure VM backups are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
  if($StorageAccountsFin.count -ne 0) {Write-Host $StorageAccountsFin.count "Storage Accounts are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
  if($pvtendpointsFin.count -ne 0) {Write-Host $pvtendpointsFin.count "Private endpoints are still linked to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
  
  $accesstoken = Get-AzAccessToken
  $token = $accesstoken.Token
  $authHeader = @{
      'Content-Type'='application/json'
      'Authorization'='Bearer ' + $token
  }
  $restUri = "$azureManagementEndpointUrl" + "subscriptions/"+ $SubscriptionId + "/resourcegroups/" + $ResourceGroup + "/providers/Microsoft.RecoveryServices/vaults/" + $VaultName + "?api-version=2021-06-01&operation=DeleteVaultUsingPS"
  $response = Invoke-RestMethod -Uri $restUri -Headers $authHeader -Method DELETE
  
  $VaultDeleted = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroup -erroraction 'silentlycontinue'
  if ($VaultDeleted -eq $null){
  Write-Host "Recovery Services Vault" $VaultName "successfully deleted"
  }
  #Finish
    }

    Write-Host "Moving to the AVD Subscription named: $avdSubscriptionName"
    Select-AzSubscription $avdSubscriptionId

    Write-Host "Looking for an Azure Recovery Services Vault named: $avdRsvName in the Resource Group named: $avdManagementRgName. If found, it will be deleted."
    $rsv = Get-AzRecoveryServicesVault -Name $avdRsvName -ResourceGroupName $avdManagementRgName -ErrorAction 'silentlycontinue'
    if ($rsv -ne $null){
      Remove-Rsv -VaultName $avdRsvName -ResourceGroup $avdManagementRgName -SubscriptionId $avdSubscriptionId -AzureManagementEndpointUrl $azureManagementEndpointUrl
    }

    Write-Host "Looking for a Data Collection Rule named: $avdDcrName in the Resource Group named: $avdManagementRgName. If found, it will be deleted."
    $dcr = $dcrToDelete = Get-AzDataCollectionRule -Name $avdDcrName -ResourceGroupName $avdManagementRgName -ErrorAction 'silentlycontinue'
    if ($dcr -ne $null){
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
        if ($rg -ne "$avdGlobalWorkspaceRgName"){
          Select-AzSubscription -SubscriptionId $avdSubscriptionId
          Remove-AzResourceGroup -Name $rg -Force
        }
        else {
          if ($finalAvdStamp -eq $true){
            Select-AzSubscription -SubscriptionId $avdGlobalWorkspaceRgSubscriptionId
            Remove-AzResourceGroup -Name $rg -Force
          }
          else {
            Write-Host "This is not the final AVD stamp. The global workspace resource group will not be deleted."
          }
          }
      }
}