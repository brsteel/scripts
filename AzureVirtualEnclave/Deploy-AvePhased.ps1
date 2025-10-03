<#
.SYNOPSIS
Two-phase Azure Virtual Enclave (AVE) deployment: Phase 1 deploys communities only (deployEnclaves=false) then, after they reach provisioningState Succeeded, Phase 2 deploys enclaves (deployEnclaves=true).

.DESCRIPTION
Helps isolate race/ordering issues causing enclave (virtual hub) creation failures by separating community provisioning from enclave provisioning and inserting a readiness wait loop.

.PARAMETER Subscription            Azure subscription name or ID.
.PARAMETER BaseName                Base name (template param baseName).
.PARAMETER Location                Canonical location (e.g. usgovvirginia).
.PARAMETER NumberOfCommunities     Number of communities (default 1).
.PARAMETER ParameterFile           Optional .bicepparam file path.
.PARAMETER TemplateFile            Path to solution.bicep (default: script directory).
.PARAMETER PollIntervalSeconds     Seconds between readiness polls (default 30).
.PARAMETER MaxWaitMinutes          Max minutes to wait for all communities (default 20).
.PARAMETER AdditionalParameters    Extra hashtable of parameter overrides.

.EXAMPLE
./Deploy-AvePhased.ps1 -Subscription CET-FFX-BRSTEEL-MLZHUB -BaseName ave1 -Location usgovvirginia -NumberOfCommunities 1 -UseCompactNames

.NOTES
Requires az CLI logged in. Outputs correlation IDs for each deployment. Saves full deployment JSON locally.
#>

[CmdletBinding()] param(
  [Parameter(Mandatory=$true)] [string] $Subscription,
  [Parameter(Mandatory=$true)] [string] $BaseName,
  [Parameter(Mandatory=$true)] [string] $Location,
  [int] $NumberOfCommunities = 1,
  [string] $ParameterFile = "",
  # Path to solution.bicep (resolved after param block if empty)
  [string] $TemplateFile = "",
  [int] $PollIntervalSeconds = 30,
  [int] $MaxWaitMinutes = 20,
  [int] $EnclaveMaxWaitMinutes = 30,
  [switch] $WaitForEnclaves = $true,
  [hashtable] $AdditionalParameters
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve template file path if not provided
if (-not $TemplateFile -or $TemplateFile.Trim() -eq "") {
  if ($PSScriptRoot) {
    $TemplateFile = Join-Path $PSScriptRoot 'solution.bicep'
  } elseif ($MyInvocation -and $MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
    $TemplateFile = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'solution.bicep'
  } else {
    throw "Unable to resolve solution.bicep path automatically; please supply -TemplateFile explicitly."
  }
}

if (-not (Test-Path $TemplateFile)) { throw "Template file not found: $TemplateFile" }

function Write-Info($msg){ Write-Host "[INFO ] $msg" -ForegroundColor Cyan }
function Write-Warn($msg){ Write-Warning $msg }
function Write-Err ($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Assert-AzCliReady {
  Write-Info "Validating Azure CLI context for subscription '$Subscription'"
  try {
    $acctJson = az account show --subscription $Subscription -o json
    if (-not $acctJson) { throw 'No account JSON returned' }
    $acct = $acctJson | ConvertFrom-Json
    $script:SubscriptionId = $acct.id
  } catch {
    throw "Azure CLI not logged in or subscription '$Subscription' not accessible. Run 'az login' / 'az account set'."
  }
  Write-Info "Resolved subscriptionId: $script:SubscriptionId"
}

function Get-ParamArgs {
  param([bool] $DeployEnclaves)
  $paramArgs = @()
  if ($ParameterFile) { $paramArgs += @('--parameters', $ParameterFile) }
  $paramArgs += @('--parameters', "baseName=$BaseName")
  $paramArgs += @('--parameters', "deployEnclaves=$DeployEnclaves")
  $paramArgs += @('--parameters', "numberOfCommunities=$NumberOfCommunities")
  if ($AdditionalParameters) {
    foreach ($k in $AdditionalParameters.Keys) { $paramArgs += @('--parameters', "$k=$($AdditionalParameters[$k])") }
  }
  return $paramArgs
}

function Invoke-PhaseDeployment {
  param(
    [Parameter(Mandatory)] [string] $PhaseName,
    [Parameter(Mandatory)] [bool] $DeployEnclaves
  )
  $timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
  $deploymentName = "ave-$PhaseName-$timestamp"
  Write-Info "Starting $PhaseName deployment: $deploymentName (deployEnclaves=$DeployEnclaves)"
  $paramArgs = Get-ParamArgs -DeployEnclaves:$DeployEnclaves
  $cmd = @(
    'deployment','sub','create',
    '--subscription', $Subscription,
    '--name', $deploymentName,
    '--location', $Location,
    '--template-file', $TemplateFile
  ) + $paramArgs
  az @cmd --only-show-errors -o json > "$deploymentName-output.json"
  Write-Info "$PhaseName deployment completed (output: $deploymentName-output.json)"
  $corr = az deployment sub show --subscription $Subscription --name $deploymentName --query properties.correlationId -o tsv
  Write-Info "$PhaseName correlationId: $corr"
  return @{ Name = $deploymentName; CorrelationId = $corr }
}

function Get-CommunityNames {
  $names = @()
  for ($i=0; $i -lt $NumberOfCommunities; $i++) {
  $names += "${BaseName}c$i"
  }
  return $names
}

function Get-CommunityIdMap {
  # Returns a hashtable: name -> id for current communities in subscription (may include more than our target names)
  $raw = az resource list --resource-type Microsoft.Mission/communities --query "[].{name:name,id:id}" -o json 2>$null
  if (-not $raw) { return @{} }
  $list = $raw | ConvertFrom-Json
  $map = @{}
  foreach ($c in $list) { $map[$c.name] = $c.id }
  return $map
}

function Get-EnclaveMap {
  $raw = az resource list --resource-type Microsoft.Mission/virtualEnclaves --query "[].{name:name,id:id}" -o json 2>$null
  if (-not $raw) { return @{} }
  $list = $raw | ConvertFrom-Json
  $map = @{}
  foreach ($e in $list) { $map[$e.name] = $e.id }
  return $map
}

function Wait-EnclavesReady {
  param(
    [string[]] $TargetEnclaveNames
  )
  if (-not $TargetEnclaveNames -or $TargetEnclaveNames.Count -eq 0) { Write-Warn 'No enclave names supplied to Wait-EnclavesReady'; return }
  $deadline = (Get-Date).AddMinutes($EnclaveMaxWaitMinutes)
  $pending = New-Object System.Collections.Generic.HashSet[string]
  $TargetEnclaveNames | ForEach-Object { [void]$pending.Add($_) }
  Write-Info "Waiting for $($pending.Count) enclave(s) to reach Succeeded (timeout ${EnclaveMaxWaitMinutes}m)"
  $map = Get-EnclaveMap
  while ($pending.Count -gt 0) {
    if ((Get-Date) -gt $deadline) {
      throw "Timeout waiting for enclaves: $([string]::Join(', ', $pending))"
    }
    foreach ($n in @($pending)) {
      if (-not $map.ContainsKey($n)) {
        # refresh map
        $map = Get-EnclaveMap
        if (-not $map.ContainsKey($n)) { Write-Warn "Enclave '$n' not yet listed"; continue }
      }
      $id = $map[$n]
      $state = az resource show --ids $id --query properties.provisioningState -o tsv 2>$null
      if ($state -eq 'Succeeded') {
        Write-Info "Enclave '$n' is Succeeded"; [void]$pending.Remove($n)
      } elseif ($state) {
        Write-Info "Enclave '$n' state: $state"
      } else {
        Write-Warn "Enclave '$n' query returned no state"
      }
    }
    if ($pending.Count -gt 0) { Start-Sleep -Seconds $PollIntervalSeconds }
  }
  Write-Info 'All enclaves Succeeded.'
}

function Wait-CommunitiesReady {
  $names = Get-CommunityNames
  if (-not $names) { throw 'Get-CommunityNames returned no names; verify NumberOfCommunities parameter.' }
  if ($names -isnot [System.Array]) { $names = @($names) }
  Write-Info ("Community names: {0}" -f ([string]::Join(', ', $names)))
  $idMap = Get-CommunityIdMap
  foreach($n in $names){ if(-not $idMap.ContainsKey($n)){ Write-Warn "Community '$n' not yet listed after phase1; will retry during polling." } }
  $deadline = (Get-Date).AddMinutes($MaxWaitMinutes)
  Write-Info "Waiting for $($names.Count) community resource(s) to reach provisioningState=Succeeded (timeout $MaxWaitMinutes min)"

  $remaining = New-Object System.Collections.Generic.HashSet[string]
  $names | ForEach-Object { [void]$remaining.Add($_) }

  while ($remaining.Count -gt 0) {
  if ((Get-Date) -gt $deadline) {
      throw "Timeout: The following communities did not become ready: $([string]::Join(', ',$remaining))"
    }
    foreach ($n in @($remaining)) {
      try {
        if (-not $idMap.ContainsKey($n)) {
          # Refresh map once per loop iteration if missing
          $idMap = Get-CommunityIdMap
          if (-not $idMap.ContainsKey($n)) { Write-Warn "Community '$n' still not discoverable via list."; continue }
        }
        $id = $idMap[$n]
        $state = az resource show --ids $id --query properties.provisioningState -o tsv 2>$null
        if ($state -eq 'Succeeded') {
          Write-Info "Community '$n' is Succeeded"
          [void]$remaining.Remove($n)
        } elseif ($state) {
          Write-Info "Community '$n' state: $state"
        } else {
          Write-Warn "Community '$n' not yet queryable"
        }
      } catch {
        Write-Warn "Query failed for community '$n': $($_.Exception.Message)"
      }
    }
    if ($remaining.Count -gt 0) { Start-Sleep -Seconds $PollIntervalSeconds }
  }
  Write-Info "All communities ready. Proceeding to enclave phase."
}

try {
  Assert-AzCliReady
  Write-Info "Phase 1: Deploying communities only"
  $phase1 = Invoke-PhaseDeployment -PhaseName 'phase1' -DeployEnclaves:$false
  Wait-CommunitiesReady
  Write-Info "Phase 2: Deploying enclaves"
  $enclavesBefore = Get-EnclaveMap
  $phase2 = Invoke-PhaseDeployment -PhaseName 'phase2' -DeployEnclaves:$true
  if ($WaitForEnclaves) {
    # Determine newly created enclaves (heuristic: names starting with baseName not present before)
    $afterMap = Get-EnclaveMap
    $newNames = @()
    foreach ($k in $afterMap.Keys) {
      if (-not $enclavesBefore.ContainsKey($k) -and $k.StartsWith($BaseName)) { $newNames += $k }
    }
    if ($newNames.Count -eq 0) { Write-Warn 'No new enclaves detected after phase2 (check naming or baseName). Polling all enclaves with baseName prefix.'; $newNames = $afterMap.Keys | Where-Object { $_.StartsWith($BaseName) } }
    if ($newNames.Count -gt 0) { Wait-EnclavesReady -TargetEnclaveNames $newNames } else { Write-Warn 'Still no enclaves to poll.' }
  } else {
    Write-Warn 'Skipping enclave readiness wait per parameter.'
  }

  Write-Host ""; Write-Host "================ Summary ================" -ForegroundColor Green
  Write-Host ("Phase1 Deployment: {0}" -f $phase1.Name)
  Write-Host ("Phase1 CorrelationId: {0}" -f $phase1.CorrelationId)
  Write-Host ("Phase2 Deployment: {0}" -f $phase2.Name)
  Write-Host ("Phase2 CorrelationId: {0}" -f $phase2.CorrelationId)
  Write-Host "===========================================" -ForegroundColor Green
}
catch {
  Write-Err $_.Exception.Message
  exit 1
}
