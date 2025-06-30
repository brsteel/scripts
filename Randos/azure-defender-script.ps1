Connect-AzAccount -Environment AzureUSGovernment -Subscription '3a8f043c-c15c-4a67-9410-a585a85f2109'
Get-AzSecurityPricing
Set-AzSecurityPricing -Name "StorageAccounts" -PricingTier "Free"
Set-AzSecurityPricing -Name "Arm" -PricingTier "Free"
Get-AzSecurityContact -Debug
$id = Get-AzSecurityWorkspaceSetting
Remove-AzSecurityWorkspaceSetting -ResourceId $id.Id