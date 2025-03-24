$Location = 'usgovvirginia'
$ResourceGroupName = 'mlz-rg-templateSpecs-az-dev'
$TemplateSpecName = 'bws-mlz-firewall-rules-mod'
New-AzTemplateSpec -ResourceGroupName $ResourceGroupName -Name $TemplateSpecName -Version 1.0 -Location $Location -TemplateFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\mlz.json' -UIFormDefinitionFile 'C:\Users\brsteel\Documents\repositories\missionlz\src\bicep\form\mlz.portal.json' -Force