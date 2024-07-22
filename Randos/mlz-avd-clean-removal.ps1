
$azureEnvironment = "AzureUSGovernment"
$avdSubscriptionName = "mlz-iac-tier3"
$mlzHubSubscriptionName = "mlz-iac-hub"
$avdIdentifier = "bws"
$avdStampIndex = "0"
$avdDeploymentDesc = "test"
$avdDeploymentLocation = "va"
$avdArtifactsResourceId = "/subscriptions/6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24/resourceGroups/bws-rg-network-operations-prod-va/providers/Microsoft.Storage/storageAccounts/bwsstopsprodva"

$avdSubscriptionId = (Get-AzSubscription -SubscriptionName $avdSubscriptionName).Id
$azureManagementEndpointUrl = (Get-AzEnvironment -Name $azureEnvironment).ResourceManagerUrl

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

Connect-AzAccount -Environment $azureEnvironment -Subscription $avdSubscriptionName

#find global workspace rg
$subscriptionList = Get-AzSubscription 
Foreach ($subscription in $subscriptionList){
    Select-AzSubscription -SubscriptionId $subscription.Id    
    $avdGlobalWorkspaceRgObj = Get-AzResourceGroup | Where-Object {$_.ResourceGroupName -like "*$avdGlobalWorkspaceRgName*"}
    If ($avdGlobalWorkspaceRgObj -ne $null){
        $avdGlobalWorkspaceRgSubscriptionId = $subscription.Id
        break
    }
}

function Remove-RoleAssignment {
  param (
    $objectId,
    $resourceGroup,
    $scope,
    $subscriptionId
  )

  Select-AzSubscription $SubscriptionId
  $roleAssignment = Get-AzRoleAssignment -ObjectId $objectId -ResourceGroupName $ResourceGroup | Remove-AzRoleAssignment
}

function Remove-Dcr {
  param (
    $dcrName,
    $resourceGroup,
    $subscriptionId
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
    $vaultName,
    $subscription,
    $resourceGroup,
    $subscriptionId,
    $azureManagementEndpointUrl
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



Remove-Rsv -vaultName $avdRsvName -resourceGroup $avdManagementRgName -subscriptionId $avdSubscriptionId -azureManagementEndpointUrl $azureManagementEndpointUrl
Remove-Dcr -subscriptionId $avdSubscriptionId -dcrName $avdDcrName -resourceGroup $avdManagementRgName

$avdDeployIdentity = Get-AzADServicePrincipal -DisplayName $avdDeployIdentityName
Remove-RoleAssignment -ObjectId $avdDeployIdentity.Id -ResourceGroup $avdArtifactsRgName -SubscriptionId $avdArtifactsSubscriptionId -Scope $avdArtifactsResourceGroupResourceId

$avdVmDeployAgentsApp = Get-AzAdServicePrincipal -DisplayName $avdVmAgentDeployAppName
Remove-RoleAssignment -ObjectId $avdVmDeployAgentsApp.Id -ResourceGroup $avdArtifactsRgName -SubscriptionId $avdArtifactsSubscriptionId -Scope $avdArtifactsResourceGroupResourceId

Select-AzSubscription -SubscriptionId $avdSubscriptionId
$avdRgList = @($avdControlPlaneRgName, $avdManagementRgName, $avdGlobalWorkspaceRgName, $avdFeedWorkspaceRgName, $avdHostsRgName, $avdNetworkRgName)
foreach ($rg in $avdRgList){
    if ($rg -ne "$avdGlobalWorkspaceRgName"){
      Remove-AzResourceGroup -Name $rg -Force
    }
    else {
      Select-AzSubscription -SubscriptionId $avdGlobalWorkspaceRgSubscriptionId
      Remove-AzResourceGroup -Name $rg -Force
    }
  }
