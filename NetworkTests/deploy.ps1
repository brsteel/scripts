$webappName = "whatsmyip"
$rgName = "BrookeSteele"
$fileName = "server.zip"
$projectRoot = "C:\Users\brsteel\Repositories\Scripts\NetworkTests"
$azCloudName = "AzureUSGovernment"

if ((Get-Location).Path -eq $projectRoot)
    {
        if (Test-Path $fileName) { Remove-Item $fileName }
        Compress-Archive -Path .\* -DestinationPath $fileName -Force
    }
else
    {
        Set-Location $projectRoot
        if (Test-Path $fileName) { Remove-Item $fileName }
        Compress-Archive -Path .\* -CompressionLevel NoCompression -DestinationPath $fileName -Force
    }

if ((az cloud show --query name -o tsv) -ne $azCloudName) 
    { 
        az cloud set --name $azCloudName
    }
if ((az account show))
{
    az webapp deployment source config-zip --resource-group $rgName --name $webappName --src ".\$fileName"
}
else
{
    az login
    az webapp deployment source config-zip --resource-group $rgName --name $webappName --src ".\$fileName"
}
 