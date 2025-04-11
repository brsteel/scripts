###Add bicep path to system path
# Define the path to add
$pathToAdd = "C:\Users\brsteel\.azure\bin"

# Get the current PATH for the user
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)

# Check if the path is already in the PATH variable
if ($currentPath -notlike "*$pathToAdd*") {
    # Add the new path to the existing PATH
    $newPath = $currentPath + ";" + $pathToAdd

    # Update the PATH environment variable for the user
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)

    Write-Host "The path '$pathToAdd' has been added to your PATH."
} else {
    Write-Host "The path '$pathToAdd' is already in your PATH."
}



##create MLZ template spec
## mlz template spec
$Location = 'usgovvirginia'
$ResourceGroupName = 'mlz-rg-templateSpecs-az-dev'
$TemplateSpecName = 'bws-mlz-firewall-rules-mod'
New-AzTemplateSpec -ResourceGroupName $ResourceGroupName -Name $TemplateSpecName -Version 1.0 -Location $Location -TemplateFile 'C:\Users\brsteel\Documents\repositories\missionlz\missionlz\src\bicep\mlz.json' -UIFormDefinitionFile 'C:\Users\brsteel\Documents\repositories\missionlz\missionlz\src\bicep\form\mlz.portal.json' -Force

# tier3 template spec
$Location = 'usgovvirginia'
$ResourceGroupName = 'mlz-rg-templateSpecs-az-dev'
$TemplateSpecName = 'bws-tier3-firewall-rules-mod'
New-AzTemplateSpec -ResourceGroupName $ResourceGroupName -Name $TemplateSpecName -Version 1.0 -Location $Location -TemplateFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\solution.json' -UIFormDefinitionFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\uiDefinition.json' -Force

# avd template spec
$Location = 'usgovvirginia'
$ResourceGroupName = 'mlz-rg-templateSpecs-az-dev'
$TemplateSpecName = 'bws-avd-firewall-rules-mod'
New-AzTemplateSpec -ResourceGroupName $ResourceGroupName -Name $TemplateSpecName -Version 1.0 -Location $Location -TemplateFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.json' -UIFormDefinitionFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\uiDefinition.json' -Force




### capture password for virtual machine admin password and store as secure string for use with POSH and plain text for use with az cli
# Prompt the user for a password and wrap it as a secure string
$password = Read-Host "Enter your password" -AsSecureString
# Convert the secure string to plain text
$passwordPlainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Prompt the user for a password and wrap it as a secure string
$sharedkey = Read-Host "Enter your sharedkey" -AsSecureString
# Convert the secure string to plain text
$sharedKeyPlainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))




#mlz deployment az cli
az deployment sub create --name bwsdeploycln1 --location usgovvirginia --template-file C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\mlz.bicep --parameters C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\mlz.bicepparam --parameters windowsVmAdminPassword=$passwordPlainText

#mlz deployment posh
New-AzSubscriptionDeployment `
  -Name "bwsdeploycln1" `
  -Location "usgovvirginia" `
  -TemplateFile "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\mlz.bicep" `
  -TemplateParameterFile "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\mlz.bicepparam" `
  -windowsVmAdminPassword $password



  
#avd deployment az cli
az deployment sub create --name bwsdeployavd --location usgovvirginia --template-file C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.bicep --parameters C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.bicepparam --parameters virtualMachineAdminPassword=$passwordPlainText

#avd deployment posh
New-AzSubscriptionDeployment `
  -Name "bwsdeployavd" `
  -Location "usgovvirginia" `
  -TemplateFile "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.bicep" `
  -TemplateParameterFile "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.bicepparam" `
  -virtualMachineAdminPassword $password



# virtual network gateway deployment az cli
az deployment sub create --name bwsdeployvgw --location usgovvirginia --template-file C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\virtual-network-gateway\solution.bicep --parameters C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\virtual-network-gateway\solution.bicepparam --parameters sharedKey=$sharedKeyPlainText

# virtual network gateway deployment posh
New-AzSubscriptionDeployment `
  -Name "bwsdeployvgw" `
  -Location "usgovvirginia" `
  -TemplateFile "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\virtual-network-gateway\solution.bicep" `
  -TemplateParameterFile "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\virtual-network-gateway\solution.bicepparam" `
  -sharedKey $sharedKey




  
# tier3 deployment az cli
az deployment sub create --name bwsdeploy --location usgovvirginia --template-file C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\solution.bicep --parameters C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\solution.bicepparam

# tier3 deployment posh
New-AzSubscriptionDeployment `
  -Name "bwsdeploy" `
  -Location "usgovvirginia" `
  -TemplateFile "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\solution.bicep" `
  -TemplateParameterFile "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\tier3\solution.bicepparam"



