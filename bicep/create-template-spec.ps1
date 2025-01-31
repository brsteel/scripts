$resourceGroupName = "mlz-rg-templateSpecs-dev-va"
$templateSpecName = "mlz-template"

New-AzTemplateSpec -ResourceGroupName $resourceGroupName -Name $templateSpecName -Version '1.0' -Location 'usgovvirginia' -TemplateFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\mlz.json' -UIFormDefinitionFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\form\mlz.portal.json' -Force

