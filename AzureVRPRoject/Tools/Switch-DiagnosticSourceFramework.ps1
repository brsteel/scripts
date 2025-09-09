param([string]$Version='7.0.0',[string]$Framework='netstandard2.0')
$ErrorActionPreference='Stop'
$base=Join-Path $PSScriptRoot "nuget-cache/System.Diagnostics.DiagnosticSource.$Version/lib/$Framework"
$dll=Join-Path $base 'System.Diagnostics.DiagnosticSource.dll'
if(!(Test-Path $dll)){ throw "DLL not found at $dll" }
$dest=Join-Path (Join-Path $PSScriptRoot '..') 'Assets/Plugins/Assemblies/System.Diagnostics.DiagnosticSource.dll'
Copy-Item $dll $dest -Force
Write-Host "Switched DiagnosticSource to $Framework ($Version)" -ForegroundColor Green
