$zipDownloadFile = "https://az2112130040005167.blob.core.windows.net/asdt/AzsEdgeDiagnostics.0.0.1483.323.zip?sp=r&st=2022-03-11T14:47:32Z&se=2022-03-25T21:47:32Z&spr=https&sv=2020-08-04&sr=b&sig=h8JrLehvgKCQA9GT3sxT5yPv9ykP%2Bx6w7XJbecuEMa8%3D"
$zipFilePath = "C:\edgekusto\AzsEdgeDiagnostics.0.0.1483.323.zip"
$kustoRootPath = "C:\edgekusto"
$kustoLibPath = "c:\edgekusto\lib"
$kustoDbPath = "c:\edgekusto\dbs"
$ingestionLogPath = "c:\logs"
$dbName = "myDB"

Remove-Item -Path $kustoRootPath -Recurse -Force

New-Item -Path $kustoRootPath -ItemType Directory -Force

Invoke-WebRequest -Uri $zipDownloadFile -OutFile $zipFilePath

Unblock-File $zipFilePath -Confirm:$false

Expand-Archive -Path $zipfilepath -DestinationPath $kustoRootPath -Force

Set-Location "$kustoLibPath"

Import-Module .\Module\Microsoft.AzureStack.Services.Analytics.EdgeKusto.dll

Start-AzSEdgeDiagnostics -KustoPath $kustoLibPath

#Wait a mmoment before trying to create db

$db1 = New-AzSEdgeDiagnosticsDatabase -Name $dbName -Directory $kustoDbPath

Import-AzSEdgeDiagnosticsLogs -DatabaseName $db1 -LogPath $ingestionLogPath

#Launch Kusto Explorer (C:\EdgeKusto\Kusto.Explorer\Kusto.Explorer.exe) and create new connection to net.tcp://localhost with Security set to None 
