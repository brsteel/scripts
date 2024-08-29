$Location = 'usgovvirginia'
$ResourceGroupName = 'mlz-rg-templateSpecs-dev-va'
$TemplateSpecName = 'ts-avd-dev-va'
New-AzTemplateSpec `
    -ResourceGroupName $ResourceGroupName `
    -Name $TemplateSpecName `
    -Version 1.0 `
    -Location $Location `
    -TemplateFile '.\src\bicep\add-ons\azure-virtual-desktop\solution.json' `
    -UIFormDefinitionFile '.\src\bicep\add-ons\azure-virtual-desktop\uiDefinition.json' `
    -Force