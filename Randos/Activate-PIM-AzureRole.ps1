# Activate-PIM-AzureRole.ps1
# Purpose: Self-activate an eligible PIM Azure RBAC role on a subscription using Microsoft Graph API.
# Notes:
#  - Works with Azure Public and Azure US Government clouds (auto-detects Graph endpoint).
#  - Uses current Azure CLI login to obtain a Microsoft Graph token; will prompt if not logged in.
#  - Requires that the signed-in user is eligible for the specified role at the provided subscription scope.
#  - PIM policies (MFA, approval, justification) still apply; the request may remain PendingApproval.

[CmdletBinding()] param(
    [Parameter(HelpMessage = "Target subscription ID (GUID). Defaults to current az account.")]
    [string] $SubscriptionId,

    [Parameter(HelpMessage = "Azure RBAC role name (e.g., Owner, Contributor) to activate. Ignored if -RoleDefinitionId is provided.")]
    [string] $RoleName = 'Owner',

    [Parameter(HelpMessage = "Azure RBAC roleDefinitionId (GUID). Overrides -RoleName if provided.")]
    [string] $RoleDefinitionId,

    [Parameter(Mandatory, HelpMessage = "Justification required by PIM policies.")]
    [string] $Justification,

    [Parameter(HelpMessage = "Activation duration in minutes (PIM maximum may apply).")]
    [int] $DurationMinutes = 120,

    [Parameter(HelpMessage = "If set, prints actions without submitting the activation request.")]
    [switch] $DryRun
)

function Get-AzCliJson {
    param([Parameter(Mandatory)][string[]] $Args)
    $json = az @Args 2>$null
    if (-not $json) { return $null }
    return $json | ConvertFrom-Json
}

    function Get-GraphBaseUrl {
    $cloud = (az cloud show --query name -o tsv) 2>$null
    if ($cloud -eq 'AzureUSGovernment') { return 'https://graph.microsoft.us' }
    return 'https://graph.microsoft.com'
}

    function Get-GraphToken {
        param([string] $GraphBase)
        # Prefer resource-type=ms-graph for proper audience per cloud, fall back to explicit resource
        $tok = (az account get-access-token --resource-type ms-graph --query accessToken -o tsv) 2>$null
        if (-not $tok) { $tok = (az account get-access-token --resource $GraphBase --query accessToken -o tsv) 2>$null }
    if (-not $tok) { throw 'Failed to get Graph access token. Ensure you are logged in: az login' }
    return $tok
}

function Invoke-GraphGet {
    param([string] $Url, [string] $Token)
    Invoke-RestMethod -Method GET -Uri $Url -Headers @{ Authorization = "Bearer $Token" } -ErrorAction Stop
}

function Invoke-GraphPost {
    param([string] $Url, [object] $Body, [string] $Token)
    $json = $Body | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Method POST -Uri $Url -Headers @{ Authorization = "Bearer $Token"; 'Content-Type' = 'application/json' } -Body $json -ErrorAction Stop
}

Write-Host "[INFO] Starting PIM activation (Azure RBAC via Microsoft Graph)..." -ForegroundColor Cyan

try {
    if (-not $SubscriptionId) {
        $sub = Get-AzCliJson -Args @('account','show','-o','json')
        if (-not $sub) { throw 'No az account context. Run az login.' }
        $SubscriptionId = $sub.id
    }
    $user = Get-AzCliJson -Args @('ad','signed-in-user','show','-o','json')
    if (-not $user) { throw 'Unable to resolve signed-in user. Ensure az is logged in with Microsoft Graph access.' }
    $principalId = $user.id

    $graph = Get-GraphBaseUrl
    $token = Get-GraphToken -GraphBase $graph

    $scope = "/subscriptions/$SubscriptionId"
    Write-Host ("[INFO] Scope: {0}" -f $scope)

    # Resolve roleDefinitionId via Azure CLI (stable mapping) if only name provided
    if (-not $RoleDefinitionId -and $RoleName) {
        $RoleDefinitionId = (az role definition list --name $RoleName --query "[0].name" -o tsv) 2>$null
        if (-not $RoleDefinitionId) { throw "Role '$RoleName' not found by az role definition list" }
        Write-Host ("[INFO] Resolved role '{0}' -> {1}" -f $RoleName, $RoleDefinitionId)
    }

    $durationIso = "PT{0}M" -f [Math]::Max(15, $DurationMinutes)
    $nowUtc = (Get-Date).ToUniversalTime().ToString('o')

    $requestBody = [ordered]@{
        action = 'SelfActivate'
        justification = $Justification
        principalId = $principalId
        roleDefinitionId = $RoleDefinitionId
    scheduleInfo = @{ startDateTime = $nowUtc; expiration = @{ type = 'AfterDuration'; duration = $durationIso } }
    scope = $scope
    }

    $reqUrl = "$graph/v1.0/roleManagement/azureResources/roleAssignmentScheduleRequests"
    Write-Host "[INFO] Submitting activation request..." -ForegroundColor Yellow
    if ($DryRun) {
        $requestBody | ConvertTo-Json -Depth 10 | Write-Output
        Write-Host "[DRYRUN] Request not submitted." -ForegroundColor DarkYellow
        return
    }

    $req = Invoke-GraphPost -Url $reqUrl -Body $requestBody -Token $token
    $reqId = $req.id
    Write-Host ("[INFO] Request created: {0} | status: {1}" -f $reqId, $req.status)

    # Poll status
    $statusUrl = "$graph/v1.0/roleManagement/azureResources/roleAssignmentScheduleRequests/$reqId"
    $maxWaitSec = 180
    $sleepSec = 5
    $elapsed = 0
    $terminal = @('Granted','Denied','Canceled','Failed')
    do {
        Start-Sleep -Seconds $sleepSec
        $elapsed += $sleepSec
        $cur = Invoke-GraphGet -Url $statusUrl -Token $token
        Write-Host ("  - [{0}s] status: {1}" -f $elapsed, $cur.status)
        if ($terminal -contains $cur.status) { break }
        if ($cur.status -eq 'PendingApproval') { break }
    } while ($elapsed -lt $maxWaitSec)

    $final = Invoke-GraphGet -Url $statusUrl -Token $token
    Write-Host ("[RESULT] Status: {0}" -f $final.status) -ForegroundColor Cyan
    if ($final.status -eq 'Granted') {
        Write-Host "[SUCCESS] PIM activation granted." -ForegroundColor Green
    } elseif ($final.status -eq 'PendingApproval') {
        Write-Host "[PENDING] Request awaits approval per PIM policy." -ForegroundColor Yellow
    } else {
        Write-Warning "Activation not granted. Inspect request in PIM or Graph.";
        $final | ConvertTo-Json -Depth 10 | Write-Output
    }
}
catch {
    Write-Host "[ERROR] $(($_ | Out-String).Trim())" -ForegroundColor Red
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $respBody = $reader.ReadToEnd()
            Write-Host "[ERROR BODY] $respBody" -ForegroundColor DarkRed
        } catch {}
    }
    exit 1
}
