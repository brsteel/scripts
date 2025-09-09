<#!
.SYNOPSIS
  Downloads required MSAL dependency assemblies for Unity and places them into Assets/Plugins/Assemblies.

.DESCRIPTION
  Fetches NuGet packages for Microsoft.IdentityModel.Abstractions and System.Diagnostics.DiagnosticSource (configurable),
  selects a preferred target framework (net462 by default, falling back to netstandard2.0, then others), and copies
  the DLLs into the Unity project so that Microsoft.Identity.Client.dll resolves references.

.PARAMETER ProjectRoot
  Path to the Unity project root (folder containing Assets). Defaults to script parent/.. assuming standard layout.

.PARAMETER Packages
  Array of package IDs to download. Defaults to required MSAL dependencies.

.PARAMETER VersionMap
  Hashtable mapping package IDs to a specific version. If omitted, latest version is resolved via NuGet V3 API.

.PARAMETER PreferredFrameworks
  Ordered list of target frameworks to search. First match wins.

.EXAMPLE
  ./Get-MSALDependencies.ps1 -ProjectRoot ..\ -Verbose

.EXAMPLE
  ./Get-MSALDependencies.ps1 -VersionMap @{ 'Microsoft.IdentityModel.Abstractions'='7.0.0'; 'System.Diagnostics.DiagnosticSource'='8.0.0' }

.NOTES
  Requires PowerShell 5+ and internet connectivity. Does not require nuget.exe or dotnet CLI.
#>
param(
  [string] $ProjectRoot = (Join-Path $PSScriptRoot '..'),
  # Include Microsoft.Identity.Client explicitly; will be skipped if already copied.
  [string[]] $Packages = @('Microsoft.Identity.Client','Microsoft.IdentityModel.Abstractions','System.Diagnostics.DiagnosticSource','Newtonsoft.Json'),
  [hashtable] $VersionMap = @{},
  [string[]] $PreferredFrameworks = @('net462','netstandard2.0','netstandard2.1','net6.0','net472'),
  [string] $LockFile = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LatestVersion {
    param([string]$PackageId)
    $index = 'https://api.nuget.org/v3-flatcontainer/{0}/index.json' -f $PackageId.ToLower()
    Write-Verbose "Querying $index"
    $resp = Invoke-RestMethod -UseBasicParsing -Uri $index
  # Filter out prerelease tags for stability; fall back if only prereleases exist.
  $stable = $resp.versions | Where-Object { $_ -notmatch '-' }
  $targetList = if ($stable) { $stable } else { $resp.versions }
  # Sort with System.Version where possible, ignore those that fail cast.
  $parsed = @()
  foreach ($v in $targetList) {
    try { [void][Version]$v; $parsed += $v } catch { }
  }
  if ($parsed.Count -gt 0) { return ($parsed | Sort-Object { [Version]$_ } | Select-Object -Last 1) }
  # If all versions failed parsing (unlikely), just return last entry.
  return ($targetList | Select-Object -Last 1)
}

function Get-PackageIfNeeded {
    param([string]$PackageId,[string]$Version,[string]$DownloadDir)
    $lower = $PackageId.ToLower()
    $nupkg = Join-Path $DownloadDir ("{0}.{1}.nupkg" -f $lower,$Version)
    if (Test-Path $nupkg) { return $nupkg }
    $url = 'https://api.nuget.org/v3-flatcontainer/{0}/{1}/{0}.{1}.nupkg' -f $lower,$Version
    Write-Host "Downloading $PackageId $Version" -ForegroundColor Cyan
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $nupkg
    return $nupkg
}

function Expand-Package {
    param([string]$NupkgPath,[string]$DestDir)
    if (!(Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir | Out-Null }
  $zipPath = $NupkgPath
  if ($NupkgPath.ToLower().EndsWith('.nupkg')) {
    $zipPath = [IO.Path]::ChangeExtension($NupkgPath, '.zip')
    if (!(Test-Path $zipPath)) { Copy-Item $NupkgPath $zipPath -Force }
  }
  Expand-Archive -Path $zipPath -DestinationPath $DestDir -Force
}

function Select-FrameworkDll {
    param([string]$ExtractDir,[string[]]$FrameworkPreference,[string]$AssemblyName)
    $libRoot = Join-Path $ExtractDir 'lib'
    if (!(Test-Path $libRoot)) { return $null }
    $candidates = Get-ChildItem $libRoot -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName $AssemblyName) }
    foreach ($fw in $FrameworkPreference) {
        $match = $candidates | Where-Object { $_.Name -ieq $fw }
        if ($match) { return (Join-Path $match[0].FullName $AssemblyName) }
    }
    # fallback first found
    return ($candidates | Select-Object -First 1 | ForEach-Object { Join-Path $_.FullName $AssemblyName })
}

if (!(Test-Path $ProjectRoot)) { throw "ProjectRoot '$ProjectRoot' not found" }
$plugins = Join-Path $ProjectRoot 'Assets/Plugins/Assemblies'
if (!(Test-Path $plugins)) { New-Item -ItemType Directory -Path $plugins | Out-Null }

$work = Join-Path $PSScriptRoot 'nuget-cache'
if (!(Test-Path $work)) { New-Item -ItemType Directory -Path $work | Out-Null }

$lockData = $null
if ($LockFile -and (Test-Path $LockFile)) {
  try { $lockData = Get-Content $LockFile -Raw | ConvertFrom-Json } catch { Write-Warning ('Failed to parse lock file ' + $LockFile + ': ' + $_) }
  if ($lockData -and (!$PSBoundParameters.ContainsKey('Packages') -or -not $PSBoundParameters['Packages'] -or $PSBoundParameters['Packages'].Count -eq 0)) {
    # Auto-populate package list from lock file if caller didn't explicitly pass -Packages
    $Packages = $lockData.packages.id
    Write-Verbose "Auto-selected packages from lock file: $($Packages -join ', ')" 
  }
}

$results = @()
foreach ($pkg in $Packages) {
  $locked = $null
  if ($lockData) { $locked = $lockData.packages | Where-Object { $_.id -ieq $pkg } | Select-Object -First 1 }
  $ver = if ($locked) { $locked.version } elseif ($VersionMap.ContainsKey($pkg)) { $VersionMap[$pkg] } else { Get-LatestVersion -PackageId $pkg }
    $nupkg = Get-PackageIfNeeded -PackageId $pkg -Version $ver -DownloadDir $work
  $extract = Join-Path $work ("{0}.{1}" -f $pkg,$ver)
  $needsExtract = $true
  if (Test-Path $extract) {
    # If lib already populated assume good; if empty (e.g. from prior failed attempt) force re-extract
    if (Test-Path (Join-Path $extract 'lib')) {
      $libItems = Get-ChildItem (Join-Path $extract 'lib') -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($libItems) { $needsExtract = $false }
    }
  }
  if ($needsExtract) { Expand-Package -NupkgPath $nupkg -DestDir $extract }
  $assemblyName = if ($locked -and $locked.assembly) { $locked.assembly } else { "$pkg.dll" }
  if ($pkg -eq 'System.Diagnostics.DiagnosticSource' -and -not $locked) { $assemblyName = 'System.Diagnostics.DiagnosticSource.dll' }
  $frameworkPref = if ($locked -and $locked.framework) { @($locked.framework) } else { $PreferredFrameworks }
  $dll = Select-FrameworkDll -ExtractDir $extract -FrameworkPreference $frameworkPref -AssemblyName $assemblyName
    if (!$dll) { Write-Warning "Could not locate assembly for $pkg"; continue }
    $dest = Join-Path $plugins (Split-Path $dll -Leaf)
    Copy-Item $dll $dest -Force
    $results += [pscustomobject]@{ Package=$pkg; Version=$ver; Framework=[IO.Directory]::GetParent($dll).Name; Output=$dest }
}

Write-Host "\nCompleted. Assemblies:" -ForegroundColor Green
$results | Format-Table -AutoSize
Write-Host "\nUnity will import these on next focus. If warnings persist, verify Plugin Inspector settings." -ForegroundColor Yellow
