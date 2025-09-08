# Assess-MLZ-Compliance-ARG.ps1
# Purpose: Query Azure Resource Graph across subscriptions for Mission Landing Zone compliance signals
# - DDoS Standard coverage (vNets without DDoS enabled/plan)
# - Log Analytics workspace retention (<90d) and public access not disabled
# - Defender for Cloud plans not at Standard
# - Traffic Analytics not enabled on NSG flow logs and NSGs missing flow logs
# Output: Console summary and CSV exports per finding in an output folder

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Subscription name contains any of these strings (case-insensitive). Leave empty to use all currently selected subscriptions.")]
    [string[]] $SubscriptionNameContains = @(),

    [Parameter(HelpMessage = "Optional: Explicit subscription Ids to scope to. Overrides -SubscriptionNameContains if provided.")]
    [string[]] $SubscriptionIds,

    [Parameter(HelpMessage = "Output folder for CSVs.")]
    [string] $OutputFolder = (Join-Path -Path (Get-Location) -ChildPath "out\mlz-compliance"),

    [Parameter(HelpMessage = "Set to true to also emit a single consolidated CSV with all findings.")]
    [switch] $EmitConsolidatedCsv
)

begin {
    Write-Host "[INFO] Starting MLZ compliance assessment via Azure Resource Graph..." -ForegroundColor Cyan

    # Pre-check Az context
    try {
        $ctx = Get-AzContext -ErrorAction Stop
        if (-not $ctx) { throw "No Azure context." }
        Write-Host ("[INFO] Azure context: {0} | Tenant: {1} | Environment: {2}" -f $ctx.Account, $ctx.Tenant, $ctx.Environment.Name)
    }
    catch {
        Write-Warning "You're not logged in to Azure. Please run Connect-AzAccount first, then re-run this script."
        return
    }

    # Ensure Az.ResourceGraph is available
    if (-not (Get-Module -ListAvailable -Name Az.ResourceGraph)) {
        Write-Warning "Az.ResourceGraph module not found. Install it with: Install-Module Az.ResourceGraph -Scope CurrentUser"
        return
    }
    Import-Module Az.ResourceGraph -ErrorAction Stop

    # Resolve subscriptions
    $allSubs = Get-AzSubscription | Sort-Object Name
    if ($SubscriptionIds -and $SubscriptionIds.Count -gt 0) {
        $targetSubs = $allSubs | Where-Object { $_.Id -in $SubscriptionIds }
    } elseif ($SubscriptionNameContains -and $SubscriptionNameContains.Count -gt 0) {
        $targetSubs = $allSubs | Where-Object { param($n) $n = $_.Name; foreach ($p in $SubscriptionNameContains) { if ($n -like ("*{0}*" -f $p)) { return $true } } return $false }
    } else {
        # Use currently selected subscriptions in context
        $targetSubs = $allSubs | Where-Object { $_.State -eq 'Enabled' -and $_.IsDefault -or $_.HomeTenantId -eq $ctx.Tenant.Id }
    }

    if (-not $targetSubs -or $targetSubs.Count -eq 0) {
        Write-Warning "No target subscriptions resolved. Adjust -SubscriptionNameContains or -SubscriptionIds."
        return
    }
    $subIds = $targetSubs.Id
    Write-Host ("[INFO] Target subscriptions: {0}" -f ($targetSubs | ForEach-Object { "`n  - {0} ({1})" -f $_.Name, $_.Id }))

    # Prepare output folder
    $null = New-Item -ItemType Directory -Path $OutputFolder -Force

    function Invoke-ARGQueryPaged {
        param(
            [Parameter(Mandatory)] [string] $Query,
            [Parameter(Mandatory)] [string[]] $Subscriptions
        )

        $all = @()
        $skipToken = $null
        do {
            $opts = @{ Query = $Query; Subscription = $Subscriptions; First = 1000 }
            if ($skipToken) { $opts.SkipToken = $skipToken }
            $page = Search-AzGraph @opts
            if ($page -and $page.Data) { $all += $page.Data }
            $skipToken = $page.SkipToken
        } while ($skipToken)
        return $all
    }

    $now = Get-Date -Format 'yyyyMMdd-HHmmss'
    $findings = @()
}

process {
    Write-Host "[STEP] Checking DDoS Standard coverage on virtual networks..." -ForegroundColor Yellow
    $queryDdos = @'
Resources
| where type =~ "microsoft.network/virtualnetworks"
| project subscriptionId, resourceGroup, name, id,
          ddosEnabled = tobool(properties.enableDdosProtection),
          ddosPlanId = tostring(properties.ddosProtectionPlan.id)
| extend ddosEnabled = iff(isnull(ddosEnabled), false, ddosEnabled)
| where ddosEnabled == false or isempty(ddosPlanId)
'@
    $ddos = Invoke-ARGQueryPaged -Query $queryDdos -Subscriptions $subIds
    $ddosPath = Join-Path $OutputFolder ("{0}_ddos_missing.csv" -f $now)
    $ddos | Export-Csv -Path $ddosPath -NoTypeInformation -Encoding UTF8
    Write-Host ("[INFO] vNets without DDoS/plan: {0} (export: {1})" -f ($ddos.Count), $ddosPath)
    $findings += $ddos | ForEach-Object { $_ | Add-Member NoteProperty finding "VNetMissingDDoS" -PassThru }

    Write-Host "[STEP] Checking Log Analytics workspace retention and public access..." -ForegroundColor Yellow
    $queryLAW = @'
Resources
| where type =~ "microsoft.operationalinsights/workspaces"
| project subscriptionId, resourceGroup, name, id,
          retention = toint(properties.retentionInDays),
          publicIngestion = tostring(properties.publicNetworkAccessForIngestion),
          publicQuery = tostring(properties.publicNetworkAccessForQuery)
| extend retention = iff(isnull(retention), 30, retention)
| where retention < 90 or publicIngestion !~ 'Disabled' or publicQuery !~ 'Disabled'
'@
    $law = Invoke-ARGQueryPaged -Query $queryLAW -Subscriptions $subIds
    $lawPath = Join-Path $OutputFolder ("{0}_loganalytics_issues.csv" -f $now)
    $law | Export-Csv -Path $lawPath -NoTypeInformation -Encoding UTF8
    Write-Host ("[INFO] Log Analytics workspaces with issues: {0} (export: {1})" -f ($law.Count), $lawPath)
    $findings += $law | ForEach-Object { $_ | Add-Member NoteProperty finding "LAWRetentionOrPublicAccess" -PassThru }

    Write-Host "[STEP] Checking Defender for Cloud plans not at Standard..." -ForegroundColor Yellow
    $queryDefender = @'
Resources
| where type =~ "microsoft.security/pricings"
| project subscriptionId, name, id, tier = tostring(properties.pricingTier)
| where tier !~ "Standard"
'@
    $def = Invoke-ARGQueryPaged -Query $queryDefender -Subscriptions $subIds
    $defPath = Join-Path $OutputFolder ("{0}_defender_not_standard.csv" -f $now)
    $def | Export-Csv -Path $defPath -NoTypeInformation -Encoding UTF8
    Write-Host ("[INFO] Defender plans not Standard: {0} (export: {1})" -f ($def.Count), $defPath)
    $findings += $def | ForEach-Object { $_ | Add-Member NoteProperty finding "DefenderPlanNotStandard" -PassThru }

    Write-Host "[STEP] Checking Traffic Analytics on NSG flow logs..." -ForegroundColor Yellow
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
    $flowNoTA = Invoke-ARGQueryPaged -Query $queryFlowNoTA -Subscriptions $subIds
    $flowNoTAPath = Join-Path $OutputFolder ("{0}_flowlogs_ta_disabled.csv" -f $now)
    $flowNoTA | Export-Csv -Path $flowNoTAPath -NoTypeInformation -Encoding UTF8
    Write-Host ("[INFO] Flow logs with TA disabled: {0} (export: {1})" -f ($flowNoTA.Count), $flowNoTAPath)
    $findings += $flowNoTA | ForEach-Object { $_ | Add-Member NoteProperty finding "FlowLogsTAOff" -PassThru }

    Write-Host "[STEP] Listing NSGs without any flow logs configured..." -ForegroundColor Yellow
    $queryNSGsWithoutFlowLogs = @'
let flowLogNSGs = Resources
| where type =~ "microsoft.network/networkwatchers/flowlogs"
| project nsgId = tostring(properties.targetResourceId);
Resources
| where type =~ "microsoft.network/networksecuritygroups"
| project subscriptionId, resourceGroup, name, id
| join kind=leftanti flowLogNSGs on $left.id == $right.nsgId
'@
    $nsgNoFL = Invoke-ARGQueryPaged -Query $queryNSGsWithoutFlowLogs -Subscriptions $subIds
    $nsgNoFLPath = Join-Path $OutputFolder ("{0}_nsg_no_flowlogs.csv" -f $now)
    $nsgNoFL | Export-Csv -Path $nsgNoFLPath -NoTypeInformation -Encoding UTF8
    Write-Host ("[INFO] NSGs without flow logs: {0} (export: {1})" -f ($nsgNoFL.Count), $nsgNoFLPath)
    $findings += $nsgNoFL | ForEach-Object { $_ | Add-Member NoteProperty finding "NSGNoFlowLogs" -PassThru }
}

end {
    if ($EmitConsolidatedCsv -and $findings.Count -gt 0) {
        $consolidatedPath = Join-Path $OutputFolder ("{0}_ALL_FINDINGS.csv" -f $now)
        $findings | Export-Csv -Path $consolidatedPath -NoTypeInformation -Encoding UTF8
        Write-Host ("[INFO] Consolidated findings: {0}" -f $consolidatedPath)
    }

    Write-Host "[DONE] Assessment complete." -ForegroundColor Green
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host ("  - vNets missing DDoS: {0}" -f ($ddos.Count))
    Write-Host ("  - LAW issues (retention/public access): {0}" -f ($law.Count))
    Write-Host ("  - Defender plans not Standard: {0}" -f ($def.Count))
    Write-Host ("  - Flow logs with TA disabled: {0}" -f ($flowNoTA.Count))
    Write-Host ("  - NSGs without flow logs: {0}" -f ($nsgNoFL.Count))

    Write-Host "Tip: Scope to BRSTEEL subs with -SubscriptionNameContains BRSTEEL, or pass explicit -SubscriptionIds." -ForegroundColor DarkGray
}
