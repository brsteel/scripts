param(
    [string] $Version = '7.0.0',
    [string] $Framework = 'net462'
)
$ErrorActionPreference='Stop'
$cache = Join-Path $PSScriptRoot 'nuget-cache'
if(!(Test-Path $cache)){ New-Item -ItemType Directory -Path $cache | Out-Null }
$id = 'System.Diagnostics.DiagnosticSource'
$lower = $id.ToLower()
$nupkg = Join-Path $cache ("$lower.$Version.nupkg")
$url = "https://api.nuget.org/v3-flatcontainer/$lower/$Version/$lower.$Version.nupkg"
Write-Host "Downloading $id $Version" -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $nupkg
$zip = [IO.Path]::ChangeExtension($nupkg,'.zip')
Copy-Item $nupkg $zip -Force
$extract = Join-Path $cache ("$id.$Version")
if(Test-Path $extract){ Remove-Item -Recurse -Force $extract }
Expand-Archive -Path $zip -DestinationPath $extract -Force
$dll = Get-ChildItem -Recurse (Join-Path $extract 'lib') -Filter System.Diagnostics.DiagnosticSource.dll | Where-Object { $_.FullName -match $Framework } | Select-Object -First 1
if(!$dll){ throw "Could not find DLL for $Framework" }
$dest = Join-Path (Join-Path $PSScriptRoot '..') 'Assets/Plugins/Assemblies/System.Diagnostics.DiagnosticSource.dll'
Copy-Item $dll.FullName $dest -Force
Write-Host "Updated DiagnosticSource -> $Version ($Framework)" -ForegroundColor Green
