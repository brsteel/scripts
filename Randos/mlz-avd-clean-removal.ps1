## Variables
$avdRsvName = 'bws-2-rsv-avd-dev-va'
$avdSubscription = 'mlz-iac-sharedServices'
$rgStrings = @(
  'rg-management-avd',
  'rg-controlPlane-avd',
  'rg-hosts-avd',
  'rg-network-avd',
  'rg-feedWorkspace-avd',
  'rg-globalWorkspace-avd'
)

$azContext = Get-AzContext
if ($azContext.Subscription.Name -ne $avdSubscription) {
  Set-AzContext -Subscription $avdSubscription
}


if ($avdRsvName -ne $null) {
    $vault = Get-AzRecoveryServicesVault -Name $avdRsvName
    
    ## Disable soft delete for the Azure Backup Recovery Services vault
    Set-AzRecoveryServicesVaultProperty -Vault $vault.ID -SoftDeleteFeatureState Disable
    
    ## Check if there are backup items in a soft-deleted state and reverse the delete operation
    $containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vault.ID | Where-Object {$_.DeleteState -eq "ToBeDeleted"}
    
    foreach ($item in $containerSoftDelete) {
        Undo-AzRecoveryServicesBackupItemDeletion -Item $item -VaultId $vault.ID -Force -Verbose
    }
    
    ## Stop protection and delete data for all backup-protected items
    $containerBackup = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $vault.ID | Where-Object {$_.DeleteState -eq "NotDeleted"}
    
    foreach ($item in $containerBackup) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $vault.ID -RemoveRecoveryPoints -Force -Verbose
    }
    
    ## Delete the Recovery Services vault 
    Remove-AzRecoveryServicesVault -Vault $vault -Verbose
}