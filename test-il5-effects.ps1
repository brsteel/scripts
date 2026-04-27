$ErrorActionPreference = 'Stop'

$il5InitiativeId = '/providers/Microsoft.Authorization/policySetDefinitions/f9a961fa-3241-4b20-adc4-bbf8ad9d7197'
$il5Initiative = Get-AzPolicySetDefinition -Id $il5InitiativeId

if (-not $il5Initiative) {
    throw 'DoD IL5 initiative not found. Verify you are connected to Azure Government.'
}

$enforcementEffects = @('Deny', 'DeployIfNotExists', 'Modify')
$enforcementDefs = @()
$auditOnlyDefs   = @()

foreach ($ref in $il5Initiative.PolicyDefinition) {
    $pol = Get-AzPolicyDefinition -Id $ref.policyDefinitionId -ErrorAction SilentlyContinue
    if (-not $pol) { continue }

    $displayName = $pol.DisplayName
    $hasEffectParam = $null -ne $pol.Parameter -and ($pol.Parameter.PSObject.Properties.Name -contains 'effect')

    if ($hasEffectParam) {
        $allowed = @($pol.Parameter.effect.allowedValues)
        $defaultVal = $pol.Parameter.effect.defaultValue
        $supportsEnforcement = (@($allowed | Where-Object { $_ -in $enforcementEffects })).Count -gt 0

        if ($supportsEnforcement) {
            $resolvedEnforcementEffect = if ($allowed -contains 'Deny') {
                'Deny'
            } elseif ($allowed -contains 'DeployIfNotExists') {
                'DeployIfNotExists'
            } else {
                (@($allowed | Where-Object { $_ -in $enforcementEffects }))[0]
            }

            $enforcementDefs += [PSCustomObject]@{
                ReferenceId        = $ref.policyDefinitionReferenceId
                PolicyDefinitionId = $ref.policyDefinitionId
                DisplayName        = $displayName
                DefaultEffect      = $defaultVal
                AllowedEffects     = ($allowed -join ', ')
                EnforcementEffect  = $resolvedEnforcementEffect
            }
        } else {
            $auditOnlyDefs += [PSCustomObject]@{
                ReferenceId   = $ref.policyDefinitionReferenceId
                DisplayName   = $displayName
                AllowedEffects = ($allowed -join ', ')
            }
        }
    } else {
        $fixedEffect = $pol.PolicyRule.then.effect
        if ($fixedEffect -and ($fixedEffect -in $enforcementEffects)) {
            $enforcementDefs += [PSCustomObject]@{
                ReferenceId        = $ref.policyDefinitionReferenceId
                PolicyDefinitionId = $ref.policyDefinitionId
                DisplayName        = $displayName
                DefaultEffect      = $fixedEffect
                AllowedEffects     = "(fixed: $fixedEffect)"
                EnforcementEffect  = $fixedEffect
            }
        }
    }
}

Write-Output ("Initiative: {0}" -f $il5Initiative.DisplayName)
Write-Output ("Version: {0}" -f $il5Initiative.Version)
Write-Output ("Total policy definitions: {0}" -f $il5Initiative.PolicyDefinition.Count)
Write-Output ("Enforcement-capable definitions: {0}" -f $enforcementDefs.Count)
Write-Output ("Audit-only definitions: {0}" -f $auditOnlyDefs.Count)
Write-Output ""
$enforcementDefs | Sort-Object ReferenceId | Select-Object -First 20 | Format-Table -AutoSize -Property ReferenceId, DefaultEffect, AllowedEffects, EnforcementEffect, DisplayName
