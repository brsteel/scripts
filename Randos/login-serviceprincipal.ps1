get-azenvironment

Connect-AzAccount -Environment AzureUSGovernment 
Remove-AzADServicePrincipal -ObjectId '98b08d37-83af-4b3e-a827-47bd2146f4bf'
Get-AzADServicePrincipal | where {$_.identifierUris -like "*Brooke*"}

$spn = New-AzADServicePrincipal -displayname "MySPN-BrookeSteele0.cxpacegov.onmicrosoft.us"

Get-AzADServicePrincipal -displayname "MySPN-BrookeSteele0.cxpacegov.onmicrosoft.us"
$cred = $spn | new-azadspcredential -pass


$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($spn.Secret)
$UnsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)



$credentials = get-credential 
Connect-AzAccount -Environment AzureUSGovernment -Credential $credentials -DeviceCode