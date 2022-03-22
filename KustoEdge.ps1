cd $kustoPath 

Import-Module .\Module\Microsoft.AzureStack.Services.Analytics.EdgeKusto.dll

Start-AzSEdgeDiagnostics -KustoPath $kustoPath

#Wait a mmoment before trying to create db

$db1 = New-AzSEdgeDiagnosticsDatabase -Name $db -Directory "$kustoPath\dbs"

Import-AzSEdgeDiagnosticsLogs -DatabaseName $db1 -LogPath $ingestlogs

#Launch Kusto Explorer (C:\EdgeKusto\Kusto.Explorer\Kusto.Explorer.exe) and create new connection to net.tcp://localhost with Security set to None 
