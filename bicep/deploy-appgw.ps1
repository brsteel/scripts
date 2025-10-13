param(
    [Parameter(Mandatory=$true)][string]$ParamFile,
    [string]$DeploymentNamePrefix = 'agw-scenarioA',
    [string]$Location = 'usgovvirginia',
    [string]$SubscriptionId = '' ,
    [switch]$SkipWhatIf
)

Write-Host "[info] Parameter file: $ParamFile" -ForegroundColor Cyan

if ($SubscriptionId) {
    Write-Host "[info] Setting subscription context to $SubscriptionId" -ForegroundColor Cyan
    az account set --subscription $SubscriptionId | Out-Null
}

# Validate param file exists
if (-not (Test-Path $ParamFile)) { throw "Parameter file not found: $ParamFile" }

# Derive deployment names (stamp with date/time for uniqueness)
$stamp = (Get-Date).ToString('yyyyMMddHHmmss')
$whatIfName = "$DeploymentNamePrefix-preview-$stamp"
$deployName = "$DeploymentNamePrefix-$stamp"

if (-not $SkipWhatIf) {
    Write-Host "[info] Running what-if deployment ($whatIfName) at subscription scope..." -ForegroundColor Yellow
    az deployment sub what-if `
        --name $whatIfName `
        --location $Location `
        --parameters @"$((Resolve-Path $ParamFile).Path)" || throw "What-if failed"

    $proceed = Read-Host "What-if complete. Proceed with create deployment? (y/N)"
    if ($proceed -notin @('y','Y')) { Write-Host "[info] Aborting per user choice."; exit 0 }
}

Write-Host "[info] Creating deployment ($deployName)..." -ForegroundColor Yellow
az deployment sub create `
    --name $deployName `
    --location $Location `
    --parameters @"$((Resolve-Path $ParamFile).Path)" || throw "Deployment failed"

Write-Host "[info] Deployment outputs:" -ForegroundColor Green
az deployment sub show --name $deployName --query properties.outputs -o json

Write-Host "[done] Completed deployment $deployName" -ForegroundColor Green