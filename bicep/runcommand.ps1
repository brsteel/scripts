az vm run-command list --vm-name "fw10vmmgtvad" --resource-group "fw1-0-rg-avd-management-va-dev"
az vm run-command show --name "Update-AvdDesktop" --vm-name "fw10vmmgtvad" --resource-group "fw1-0-rg-avd-management-va-dev" --expand instanceView



$scriptContent = Get-Content -Path "c:\Users\brsteel\Documents\repositories\missionlz\missionlz\src\bicep\add-ons\azure-virtual-desktop\artifacts\Update-AvdDesktop.ps1" -Raw

az vm run-command invoke `
  --command-id RunPowerShellScript `
  --name "fw10vmmgtvad" `
  --resource-group "fw1-0-rg-avd-management-va-dev" `
  --scripts $scriptContent `
  --parameters `
    ApplicationGroupName="fw1-0-vdag-desktop-avd-va-dev" `
    FriendlyName="desktop" `
    ResourceGroupName="fw1-0-rg-avd-management-va-dev" `
    ResourceManagerUri="https://management.usgovcloudapi.net" `
    SubscriptionId="afb59830-1fc9-44c9-bba3-04f657483578" `
    UserAssignedIdentityClientId="6ed5122f-26d2-4b0d-a687-d57863dd5ae0"




