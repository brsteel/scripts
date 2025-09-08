# Assess-MLZ-Compliance-ARG-CLI.ps1
# Purpose: Same checks as Assess-MLZ-Compliance-ARG.ps1 but using Azure CLI (az) Resource Graph, reusing current az login.

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Subscription name contains any of these strings (case-insensitive). Leave empty to use default enabled subscriptions.")]
    [string[]] $SubscriptionNameContains = @(),

    [Parameter(HelpMessage = "Optional: Explicit subscription Ids to scope to. Overrides -SubscriptionNameContains if provided.")]
    [string[]] $SubscriptionIds,

    [Parameter(HelpMessage = "Output folder for CSVs.")]
    [string] $OutputFolder = (Join-Path -Path (Get-Location) -ChildPath "out\mlz-compliance"),

    [Parameter(HelpMessage = "Set to true to also emit a single consolidated CSV with all findings.")]
    [switch] $EmitConsolidatedCsv
)

function Invoke-AzGraphCliQueryPaged {
    param(
        [Parameter(Mandatory)] [string] $Query,
        [Parameter(Mandatory)] [string[]] $Subscriptions
    )
    $all = @()
    $skipToken = $null
    do {
        $args = @(
            'graph','query','-q', $Query,
            '--subscriptions', ($Subscriptions -join ','),
            '--first','1000','-o','json'
        )
        if ($skipToken) { $args += @('--skip-token', $skipToken) }
        $json = az @args 2>$null
        if (-not $json) { break }
        $obj = $json | ConvertFrom-Json
        if ($obj.data) { $all += $obj.data }
        $skipToken = $obj.skipToken
    } while ($skipToken)
    return $all
}

Write-Host "[INFO] Using Azure CLI context: $(az account show --query \"{name:name, tenantId:tenantId, cloudName:environmentName}\" -o tsv)" -ForegroundColor Cyan

try { $null = az account show -o none } catch { Write-Warning "You are not logged in with az. Run 'az login' (Gov: az cloud set -n AzureUSGovernment; az login)"; return }

# Resolve subscriptions
if ($SubscriptionIds -and $SubscriptionIds.Count -gt 0) {
    $subObjs = az account list -o json | ConvertFrom-Json | Where-Object { $_.id -in $SubscriptionIds }
} elseif ($SubscriptionNameContains -and $SubscriptionNameContains.Count -gt 0) {
    $subObjs = az account list -o json | ConvertFrom-Json | Where-Object {
        $n = $_.name
        foreach ($p in $SubscriptionNameContains) { if ($n -like "*${p}*") { return $true } }
        return $false
    }
} else {
    $subObjs = az account list -o json | ConvertFrom-Json | Where-Object { $_.state -eq 'Enabled' -and ($_.isDefault -or $_.homeTenantId -ne $null) }
}

if (-not $subObjs) { Write-Warning "No subscriptions resolved."; return }
$subs = $subObjs.id
Write-Host ("[INFO] Target subscriptions: {0}" -f ($subObjs | ForEach-Object { "`n  - {0} ({1})" -f $_.name, $_.id }))

$null = New-Item -ItemType Directory -Path $OutputFolder -Force
$now = Get-Date -Format 'yyyyMMdd-HHmmss'
$findings = @()

# Queries
$queryDdos = @'
Resources
| where type =~ "microsoft.network/virtualnetworks"
| project subscriptionId, resourceGroup, name, id,
          ddosEnabled = tobool(properties.enableDdosProtection),
          ddosPlanId = tostring(properties.ddosProtectionPlan.id)
| extend ddosEnabled = iff(isnull(ddosEnabled), false, ddosEnabled)
| where ddosEnabled == false or isempty(ddosPlanId)
'@

$queryLAW = @'
Resources
| where type =~ "microsoft.operationalinsights/workspaces"
| project subscriptionId, resourceGroup, name, id,
          retention = toint(properties.retentionInDays),
          publicIngestion = tostring(properties.publicNetworkAccessForIngestion),
          publicQuery = tostring(properties.publicNetworkAccessForQuery)
| extend retention = iff(isnull(retention), 30, retention)
| where retention < 90 or publicIngestion !~ "Disabled" or publicQuery !~ "Disabled"
'@

$queryDefender = @'
Resources
| where type =~ "microsoft.security/pricings"
| project subscriptionId, name, id, tier = tostring(properties.pricingTier)
| where tier !~ "Standard"
'@

$queryFlowNoTA = @'
Resources
| where type =~ "microsoft.network/networkwatchers/flowlogs"
| project subscriptionId, resourceGroup, name, id,
          enabled = tobool(properties.enabled),
          taEnabled = tobool(properties.trafficAnalyticsConfiguration.enabled),
          taInterval = toint(properties.trafficAnalyticsConfiguration.trafficAnalyticsInterval),
          targetResourceId = tostring(properties.targetResourceId)
| where enabled == true and (isnull(taEnabled) or taEnabled == false)
'@

$queryNSGsWithoutFlowLogs = @'
let flowLogNSGs = Resources
| where type =~ "microsoft.network/networkwatchers/flowlogs"
| project nsgId = tostring(properties.targetResourceId);
Resources
| where type =~ "microsoft.network/networksecuritygroups"
| project subscriptionId, resourceGroup, name, id
| join kind=leftanti flowLogNSGs on $left.id == $right.nsgId
'@

# Execute
Write-Host "[STEP] vNets missing DDoS or plan..." -ForegroundColor Yellow
$ddos = Invoke-AzGraphCliQueryPaged -Query $queryDdos -Subscriptions $subs
$ddosPath = Join-Path $OutputFolder ("{0}_ddos_missing.csv" -f $now)
$ddos | Export-Csv -Path $ddosPath -NoTypeInformation -Encoding UTF8
$findings += $ddos | ForEach-Object { $_ | Add-Member NoteProperty finding "VNetMissingDDoS" -PassThru }
Write-Host ("[INFO] vNets without DDoS/plan: {0} (export: {1})" -f ($ddos.Count), $ddosPath)

Write-Host "[STEP] Log Analytics retention/public access..." -ForegroundColor Yellow
$law = Invoke-AzGraphCliQueryPaged -Query $queryLAW -Subscriptions $subs
$lawPath = Join-Path $OutputFolder ("{0}_loganalytics_issues.csv" -f $now)
$law | Export-Csv -Path $lawPath -NoTypeInformation -Encoding UTF8
$findings += $law | ForEach-Object { $_ | Add-Member NoteProperty finding "LAWRetentionOrPublicAccess" -PassThru }
Write-Host ("[INFO] LAW issues: {0} (export: {1})" -f ($law.Count), $lawPath)

Write-Host "[STEP] Defender for Cloud plans not Standard..." -ForegroundColor Yellow
$def = Invoke-AzGraphCliQueryPaged -Query $queryDefender -Subscriptions $subs
$defPath = Join-Path $OutputFolder ("{0}_defender_not_standard.csv" -f $now)
$def | Export-Csv -Path $defPath -NoTypeInformation -Encoding UTF8
$findings += $def | ForEach-Object { $_ | Add-Member NoteProperty finding "DefenderPlanNotStandard" -PassThru }
Write-Host ("[INFO] Defender plans not Standard: {0} (export: {1})" -f ($def.Count), $defPath)

Write-Host "[STEP] Flow logs with Traffic Analytics disabled..." -ForegroundColor Yellow
$flowNoTA = Invoke-AzGraphCliQueryPaged -Query $queryFlowNoTA -Subscriptions $subs
$flowNoTAPath = Join-Path $OutputFolder ("{0}_flowlogs_ta_disabled.csv" -f $now)
$flowNoTA | Export-Csv -Path $flowNoTAPath -NoTypeInformation -Encoding UTF8
$findings += $flowNoTA | ForEach-Object { $_ | Add-Member NoteProperty finding "FlowLogsTAOff" -PassThru }
Write-Host ("[INFO] Flow logs TA disabled: {0} (export: {1})" -f ($flowNoTA.Count), $flowNoTAPath)

Write-Host "[STEP] NSGs without any flow logs..." -ForegroundColor Yellow
$nsgNoFL = Invoke-AzGraphCliQueryPaged -Query $queryNSGsWithoutFlowLogs -Subscriptions $subs
$nsgNoFLPath = Join-Path $OutputFolder ("{0}_nsg_no_flowlogs.csv" -f $now)
$nsgNoFL | Export-Csv -Path $nsgNoFLPath -NoTypeInformation -Encoding UTF8
$findings += $nsgNoFL | ForEach-Object { $_ | Add-Member NoteProperty finding "NSGNoFlowLogs" -PassThru }
Write-Host ("[INFO] NSGs without flow logs: {0} (export: {1})" -f ($nsgNoFL.Count), $nsgNoFLPath)

if ($EmitConsolidatedCsv -and $findings.Count -gt 0) {
    $consolidatedPath = Join-Path $OutputFolder ("{0}_ALL_FINDINGS.csv" -f $now)
    $findings | Export-Csv -Path $consolidatedPath -NoTypeInformation -Encoding UTF8
    Write-Host ("[INFO] Consolidated findings: {0}" -f $consolidatedPath)
}

Write-Host "[DONE] Assessment complete." -ForegroundColor Green
