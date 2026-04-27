param(
    [string]$OutputCsvPath = '.\IL5_EnforcementCapableDefinitions.csv',
    [switch]$NoConsoleTable
)

$ErrorActionPreference = 'Stop'

# Built-in DoD IL5 initiative (Azure Government)
$il5InitiativeId = '/providers/Microsoft.Authorization/policySetDefinitions/f9a961fa-3241-4b20-adc4-bbf8ad9d7197'
$enforcementEffects = @('Deny', 'DeployIfNotExists', 'Modify')

$il5Initiative = Get-AzPolicySetDefinition -Id $il5InitiativeId
if (-not $il5Initiative) {
    throw 'DoD IL5 initiative not found.'
}

$enforcementDefs = @()

foreach ($ref in $il5Initiative.PolicyDefinition) {
    $pol = Get-AzPolicyDefinition -Id $ref.policyDefinitionId -ErrorAction SilentlyContinue
    if (-not $pol) { continue }

    $hasEffectParam = $null -ne $pol.Parameter -and ($pol.Parameter.PSObject.Properties.Name -contains 'effect')

    if ($hasEffectParam) {
        $allowed = @($pol.Parameter.effect.allowedValues)
        $defaultVal = $pol.Parameter.effect.defaultValue
        $supportedEnforcement = @($allowed | Where-Object { $_ -in $enforcementEffects })

        if ($supportedEnforcement.Count -gt 0) {
            $chosen = if ($allowed -contains 'Deny') {
                'Deny'
            } elseif ($allowed -contains 'DeployIfNotExists') {
                'DeployIfNotExists'
            } else {
                $supportedEnforcement[0]
            }

            $enforcementDefs += [PSCustomObject]@{
                ReferenceId        = $ref.policyDefinitionReferenceId
                PolicyDefinitionId = $ref.policyDefinitionId
                DisplayName        = $pol.DisplayName
                DefaultEffect      = $defaultVal
                AllowedEffects     = ($allowed -join ', ')
                PreferredEffect    = $chosen
            }
        }
    } else {
        $fixedEffect = $pol.PolicyRule.then.effect
        if ($fixedEffect -and ($fixedEffect -in $enforcementEffects)) {
            $enforcementDefs += [PSCustomObject]@{
                ReferenceId        = $ref.policyDefinitionReferenceId
                PolicyDefinitionId = $ref.policyDefinitionId
                DisplayName        = $pol.DisplayName
                DefaultEffect      = $fixedEffect
                AllowedEffects     = "(fixed: $fixedEffect)"
                PreferredEffect    = $fixedEffect
            }
        }
    }
}

$enforcementDefs = $enforcementDefs | Sort-Object ReferenceId -Unique

Write-Output ("Initiative: {0}" -f $il5Initiative.DisplayName)
Write-Output ("Version: {0}" -f $il5Initiative.Version)
Write-Output ("Enforcement-capable definitions: {0}" -f $enforcementDefs.Count)
Write-Output ''

$enforcementDefs | Export-Csv -Path $OutputCsvPath -NoTypeInformation

if (-not $NoConsoleTable) {
    $enforcementDefs | Format-Table -AutoSize -Property ReferenceId, DisplayName, DefaultEffect, PreferredEffect, AllowedEffects
}

Write-Output ''
Write-Output ("CSV exported: {0}" -f (Resolve-Path -Path $OutputCsvPath))
