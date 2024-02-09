#Remove-Item .\myipaddressandfileupload.zip
#compress-archive . -DestinationPath myipaddressandfileupload.zip
az cloud set --name AzureUSGovernment
az login
az webapp deployment source config-zip --resource-group BrookeSteele --name myipaddressandfileupload --src .\server.zip