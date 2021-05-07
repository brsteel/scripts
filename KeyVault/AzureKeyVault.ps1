
 $VMRGName = 'Test-MyStuff';
 $vmName = 'TestEncryption';
 $KeyVault = Get-AzKeyVault -ResourceGroupName $VMRGName -VaultName 'TestEncryptionKeyV'
 $diskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
 $KeyVaultResourceId = $KeyVault.ResourceId;

 Set-AzVMDiskEncryptionExtension -ResourceGroupName $VMRGname -VMName $vmName -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId;

 Disable-AzVMDiskEncryption -VMName $vmName
