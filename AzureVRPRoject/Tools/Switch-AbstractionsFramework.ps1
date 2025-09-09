param([string]$Version='8.14.0',[string]$Framework='netstandard2.0')
$ErrorActionPreference='Stop'
$base=Join-Path $PSScriptRoot "nuget-cache/Microsoft.IdentityModel.Abstractions.$Version/lib/$Framework"
$dll=Join-Path $base 'Microsoft.IdentityModel.Abstractions.dll'
if(!(Test-Path $dll)){ throw "DLL not found at $dll" }
$dest=Join-Path (Join-Path $PSScriptRoot '..') 'Assets/Plugins/Assemblies/Microsoft.IdentityModel.Abstractions.dll'
Copy-Item $dll $dest -Force
Write-Host "Switched Abstractions to $Framework ($Version)" -ForegroundColor Green
