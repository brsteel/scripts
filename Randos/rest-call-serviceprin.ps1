# Define the variables
$tenantId = "3666803f-d1e4-4080-892b-52f70517b979"
$clientId = "6d2e859d-2bfb-4dce-a1f4-00fc280ee295"
$clientSecret = "678VEmw-rE0vZ~D4nUV56Hp9T30~O36G~j"
$scope = "https://graph.microsoft.us/.default"
#$graphApiUrl = "https://graph.microsoft.us/v1.0/serviceprincipals
$graphApiUrl = "https://graph.microsoft.us/v1.0/serviceprincipals?$filter=appId eq '9cdead84-a844-4324-93f2-b2e6bb768d07'"
#$graphApiUrl = "https://graph.microsoft.us/v1.0/serviceprincipals?$filter=startswith(displayName, 'a')&$count=true&$top=1&$orderby=displayName"

# Get the access token
$body = @{
    grant_type    = "client_credentials"
    scope         = $scope
    client_id     = $clientId
    client_secret = $clientSecret
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.us/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body
$accessToken = $tokenResponse.access_token

# Make the API call
$response = Invoke-WebRequest -Method Get -Uri $graphApiUrl -Headers @{ Authorization = "Bearer $accessToken" }

# Output the response
$response