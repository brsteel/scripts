Connect-MgGraph -Environment "USGov" -Scopes "Organization.ReadWrite.All"
$OrgID = (Get-MgOrganization).id

$uri = "https://graph.microsoft.us/beta/organization/$orgid"

$body = @'
        {
            
            "onPremisesSyncEnabled": 'false'
        }
'@

Invoke-MgGraphRequest -uri $uri -Body $body -Method PATCH