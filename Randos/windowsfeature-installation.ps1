[CmdletBinding()]
param (
    [string]
    $FeatureName
)
Install-WindowsFeature -Name $FeatureName -includeManagementTools