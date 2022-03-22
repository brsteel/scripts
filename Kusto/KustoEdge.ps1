$zipfilepath = "C:\Users\brsteel\Downloads\AzsEdgeDiagnostics.0.0.1483.323.zip"
$kustoRootPath = "C:\edgekusto"
$kustoLibPath = "c:\edgekusto\lib"
$kustoDbPath = "c:\edgekusto\dbs"
$ingestionLogPath = "c:\logs"
$dbName = "myDB"

New-Item -Path $kustoRootPath -ItemType Directory

Expand-Archive -Path $zipfilepath -DestinationPath $kustoRootPath

Set-Location "$kustoLibPath"

Import-Module .\Module\Microsoft.AzureStack.Services.Analytics.EdgeKusto.dll

Start-AzSEdgeDiagnostics -KustoPath $kustoLibPath

#Wait a mmoment before trying to create db

$db1 = New-AzSEdgeDiagnosticsDatabase -Name $dbName -Directory $kustoDbPath

Import-AzSEdgeDiagnosticsLogs -DatabaseName $db1 -LogPath $ingestionLogPath

#Launch Kusto Explorer (C:\EdgeKusto\Kusto.Explorer\Kusto.Explorer.exe) and create new connection to net.tcp://localhost with Security set to None 
