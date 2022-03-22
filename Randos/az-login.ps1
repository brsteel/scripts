$subId = ''
$tenantId = ''

$azEnvParams = @{
    name = 'USSEC'
    activeDirectoryAuthority = 'https://login.microsoftonline.microsoft.scloud'
    activeDirectoryServiceEndpointResourceId = 'htts://management.azure.microsoft.scloud'
    resourceManagerEndpoint = 'https://usseceast.management.azure.microsoft.scloud'
    graphUrl = 'https://graph.cloudapi.microsoft.scloud'
    graphEndpointResourceId = 'https://graph.cloudapi.microsoft.scloud'
    azureKeyVaultDnsSuffix = 'vault.cloudapi.microsoft.scloud'
    azureKeyVaultServiceEndpointResourceId = 'https://vault.cloudapi.microsoft.scloud'
}

Add-AzEnvironment @azEnvParams

Connect-AzAccount -Environment AzUSSec -Subscription $subId -TenantId $tenantId

#or

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$url = 'https://management.azure.microsoft.com/metadata/endpoints?api-version=2020-06-01'
$env = Add-AzEnvironment -PublishSettingsFileUrl $url
Connect-AzAccount -Environment $env.where({$_.type -eq 'Discovered'}).Name -Tenant $tenantId -Subscription $subId -UseDeviceAuthentication


