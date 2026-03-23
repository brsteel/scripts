[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GroupObjectId,

    [Parameter(Mandatory = $true)]
    [string]$MemberObjectId,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Assert-AzCli {
    $null = Get-Command az -ErrorAction Stop
}

function Ensure-LoggedIn {
    try {
        $null = az account show --query id -o tsv 2>$null
    }
    catch {
        throw 'Azure CLI is not logged in. Run: az login'
    }
}

function Assert-DirectoryObjectExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ObjectId,
        [Parameter(Mandatory = $true)]
        [string]$ObjectTypeLabel
    )

    $exists = az ad sp show --id $ObjectId --query id -o tsv 2>$null
    if (-not $exists) {
        throw "$ObjectTypeLabel object '$ObjectId' was not found in Entra ID."
    }
}

function Assert-GroupExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupId
    )

    $exists = az ad group show --group $GroupId --query id -o tsv 2>$null
    if (-not $exists) {
        throw "Group '$GroupId' was not found in Entra ID."
    }
}

function Test-GroupMember {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        [Parameter(Mandatory = $true)]
        [string]$MemberId
    )

    $isMember = az ad group member check --group $GroupId --member-id $MemberId --query value -o tsv 2>$null
    return ($isMember -eq 'true')
}

Assert-AzCli
Ensure-LoggedIn
Assert-GroupExists -GroupId $GroupObjectId
Assert-DirectoryObjectExists -ObjectId $MemberObjectId -ObjectTypeLabel 'Managed identity service principal'

if ((Test-GroupMember -GroupId $GroupObjectId -MemberId $MemberObjectId) -and -not $Force) {
    Write-Host "No change: member '$MemberObjectId' is already in group '$GroupObjectId'."
    exit 0
}

az ad group member add --group $GroupObjectId --member-id $MemberObjectId | Out-Null

if (Test-GroupMember -GroupId $GroupObjectId -MemberId $MemberObjectId) {
    Write-Host "Success: added member '$MemberObjectId' to group '$GroupObjectId'."
    exit 0
}

throw "Add operation returned, but membership verification failed for member '$MemberObjectId' in group '$GroupObjectId'."
