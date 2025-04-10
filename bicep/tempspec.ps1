# Prompt the user for a password and wrap it as a secure string
$password = Read-Host "Enter your password" -AsSecureString

# Convert the secure string to plain text
$passwordPlainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))


## mlz template spec
$Location = 'usgovvirginia'
$ResourceGroupName = 'mlz-rg-templateSpecs-az-dev'
$TemplateSpecName = 'bws-mlz-firewall-rules-mod'
New-AzTemplateSpec -ResourceGroupName $ResourceGroupName -Name $TemplateSpecName -Version 1.0 -Location $Location -TemplateFile 'C:\Users\brsteel\Documents\repositories\missionlz\missionlz\src\bicep\mlz.json' -UIFormDefinitionFile 'C:\Users\brsteel\Documents\repositories\missionlz\missionlz\src\bicep\form\mlz.portal.json' -Force

#mlz deployment
az deployment sub create --name bwsdeploycln1 --location usgovvirginia --template-file C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\mlz.bicep --parameters C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\mlz.bicepparam --parameters windowsVmAdminPassword=$passwordPlainText

# tier3 template spec
$Location = 'usgovvirginia'
$ResourceGroupName = 'mlz-rg-templateSpecs-az-dev'
$TemplateSpecName = 'bws-tier3-firewall-rules-mod'
New-AzTemplateSpec -ResourceGroupName $ResourceGroupName -Name $TemplateSpecName -Version 1.0 -Location $Location -TemplateFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\solution.json' -UIFormDefinitionFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\uiDefinition.json' -Force

# tier3
az deployment sub create --name bwsdeploy --location usgovvirginia --template-file C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\solution.bicep --parameters C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\solution.bicepparam

# avd template spec
$Location = 'usgovvirginia'
$ResourceGroupName = 'mlz-rg-templateSpecs-az-dev'
$TemplateSpecName = 'bws-avd-firewall-rules-mod'
New-AzTemplateSpec -ResourceGroupName $ResourceGroupName -Name $TemplateSpecName -Version 1.0 -Location $Location -TemplateFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.json' -UIFormDefinitionFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\uiDefinition.json' -Force


#avd deployment
az deployment sub create --name bwsdeployavd --location usgovvirginia --template-file C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.bicep --parameters C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.bicepparam --parameters virtualMachineAdminPassword=$passwordPlainText

# Prompt the user for a password and wrap it as a secure string
$sharedkey = Read-Host "Enter your sharedkey" -AsSecureString

# Convert the secure string to plain text
$sharedKeyPlainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Output to confirm the variable is set (optional, for testing purposes)
Write-Host "Value has been securely stored in the variable `$sharedkey`."

az deployment sub create --name bwsdeployvgw --location usgovvirginia --template-file C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\virtual-network-gateway\solution.bicep --parameters C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\virtual-network-gateway\solution.bicepparam --parameters sharedKey=$sharedKeyPlainText





