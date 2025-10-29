Param(
    [string[]]$TargetIps = @('10.0.130.8','10.0.131.18','10.0.132.8'),
    [string]$OutputPath = "backend-mapping.json"
)

# Discover backend VMs by private IP across all accessible subscriptions.
# Strategy:
# 1. Enumerate subscriptions (az account list)
# 2. For each subscription, set context and list NICs
# 3. Match NIC private IPs to target list
# 4. Extract VM Id (if attached), parse RG and VM name
# 5. Emit mapping JSON: [{ ip, subscriptionId, resourceGroup, vmName }]

function Get-NicMatchesForIp {
    param(
        [string]$Ip
    )
    $nicsJson = az network nic list --query "[?ipConfigurations[?privateIpAddress=='$Ip']]" -o json 2>$null
    if(-not $nicsJson){ return @() }
    $nics = $nicsJson | ConvertFrom-Json
    return $nics
}

$subsJson = az account list -o json 2>$null
if(-not $subsJson){ Write-Error "Failed to list subscriptions (ensure az CLI login)."; exit 1 }
$subs = $subsJson | ConvertFrom-Json

$results = @()
foreach($sub in $subs){
    $sid = $sub.id
    az account set -s $sid | Out-Null
    foreach($ip in $TargetIps){
        $nicMatches = Get-NicMatchesForIp -Ip $ip
        foreach($m in $nicMatches){
            $vmId = $m.virtualMachine.id
            if([string]::IsNullOrEmpty($vmId)){ continue }
            # vmId format: /subscriptions/{sid}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{vm}
            $parts = $vmId -split '/'
            $rgIndex = [Array]::IndexOf($parts,'resourceGroups') + 1
            $vmIndex = [Array]::IndexOf($parts,'virtualMachines') + 1
            $rgName = $parts[$rgIndex]
            $vmName = $parts[$vmIndex]
            $results += [pscustomobject]@{
                ip = $ip
                subscriptionId = $sid
                resourceGroup = $rgName
                vmName = $vmName
            }
        }
    }
}

# De-duplicate by IP (take first if multiple)
$final = @()
foreach($ip in $TargetIps){
    $candidate = $results | Where-Object { $_.ip -eq $ip } | Select-Object -First 1
    if($candidate){ $final += $candidate }
}

$final | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Discovery complete. Mapping written to $OutputPath" -ForegroundColor Green
$final | Format-Table -AutoSize
