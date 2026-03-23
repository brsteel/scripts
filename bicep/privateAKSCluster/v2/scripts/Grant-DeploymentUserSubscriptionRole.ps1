[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$UserObjectId,

    [Parameter(Mandatory = $false)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $false)]
    [string]$RoleName = 'Contributor'
)

$ErrorActionPreference = 'Stop'

function Assert-AzCli {
    $null = Get-Command az -ErrorAction Stop
}

function Test-AzLogin {
    try {
        $null = az account show --query id -o tsv 2>$null
    }
    catch {
        throw 'Azure CLI is not logged in. Run: az login'
    }
}

function Resolve-UserObjectId {
    param(
        [Parameter(Mandatory = $false)]
        [string]$ObjectId,
        [Parameter(Mandatory = $false)]
        [string]$Upn
    )

    if (-not [string]::IsNullOrWhiteSpace($ObjectId)) {
        $resolved = az ad user show --id $ObjectId --query id -o tsv 2>$null
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            return $resolved
        }
        throw "User object '$ObjectId' was not found in Entra ID."
    }

    if (-not [string]::IsNullOrWhiteSpace($Upn)) {
        $resolved = az ad user show --id $Upn --query id -o tsv 2>$null
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            return $resolved
        }
        throw "User principal '$Upn' was not found in Entra ID."
    }

    throw 'Provide either -UserObjectId or -UserPrincipalName.'
}

Assert-AzCli
Test-AzLogin

$resolvedUserObjectId = Resolve-UserObjectId -ObjectId $UserObjectId -Upn $UserPrincipalName
$scope = "/subscriptions/$SubscriptionId"

$null = az account set --subscription $SubscriptionId

$existing = az role assignment list --assignee $resolvedUserObjectId --scope $scope --query "[?roleDefinitionName=='$RoleName'] | [0].id" -o tsv 2>$null
if (-not [string]::IsNullOrWhiteSpace($existing)) {
    Write-Host "No change: user '$resolvedUserObjectId' already has role '$RoleName' at scope '$scope'."
    exit 0
}

az role assignment create --assignee $resolvedUserObjectId --role $RoleName --scope $scope | Out-Null

$verify = az role assignment list --assignee $resolvedUserObjectId --scope $scope --query "[?roleDefinitionName=='$RoleName'] | [0].id" -o tsv 2>$null
if (-not [string]::IsNullOrWhiteSpace($verify)) {
    Write-Host "Success: granted role '$RoleName' to user '$resolvedUserObjectId' at scope '$scope'."
    exit 0
}

throw "Role assignment verification failed for user '$resolvedUserObjectId', role '$RoleName', scope '$scope'."
