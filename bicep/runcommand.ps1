az vm run-command list --vm-name "cln0vmmgtvad" --resource-group "cln-0-rg-avd-management-va-dev"
az vm run-command show --name "Update-AvdDesktop" --vm-name "cln0vmmgtvad" --resource-group "cln-0-rg-avd-management-va-dev" --expand instanceView



$scriptContent = Get-Content -Path "c:\Users\brsteel\Documents\repositories\missionlz\src\bicep\add-ons\azure-virtual-desktop\artifacts\Update-AvdDesktop.ps1" -Encoding UTF8 -Raw

az vm run-command invoke `
  --command-id RunPowerShellScript `
  --name "cln0vmmgtvad" `
  --resource-group "cln-0-rg-avd-management-va-dev" `
  --scripts $scriptContent `
  --parameters `
    ApplicationGroupName="cln-0-vdag-desktop-avd-va-dev" `
    FriendlyName="desktop" `
    ResourceGroupName="cln-0-rg-avd-management-va-dev" `
    ResourceManagerUri="https://management.usgovcloudapi.net" `
    SubscriptionId="afb59830-1fc9-44c9-bba3-04f657483578" `
    UserAssignedIdentityClientId="148c7ed8-5996-43be-9b75-072241f3f2e4"




