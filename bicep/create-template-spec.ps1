$resourceGroupName = "mlz-rg-templateSpecs-dev-va"
$templateSpecName = "avd-template"

New-AzTemplateSpec -ResourceGroupName $resourceGroupName -Name $templateSpecName -Version '1.0' -Location 'usgovvirginia' -TemplateFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.json' -UIFormDefinitionFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\uiDefinition.json' -Force


$hubSubscriptionId = "afb59830-1fc9-44c9-bba3-04f657483578"
$identitySubscriptionId = "d9cb6670-f9bf-416f-aa7b-2d6936edcaeb"
$operationsSubscriptionId = "6d2cdf2f-3fbe-4679-95ba-4e8b7d9aed24"
$sharedServicesSubscriptionId = "3a8f043c-c15c-4a67-9410-a585a85f2109"
$templatePath = "C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\solution.json"
$lzPrefix = "mlz"
$lzLocation = "usgovvirginia"
$deploymentName = "avd-deployment"


New-AzSubscriptionDeployment `
  -Name $deploymentName `
  -Location $lzLocation `
  -TemplateFile $templatePath `
  -resourcePrefix $lzPrefix `
  -hubSubscriptionId $hubSubscriptionId `
  -identitySubscriptionId $identitySubscriptionId `
  -operationsSubscriptionId $operationsSubscriptionId `
  -sharedServicesSubscriptionId $sharedServicesSubscriptionId
