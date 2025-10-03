# Azure Virtual Enclave Cleanup Script
# This script removes all resources deployed by the Azure Virtual Enclave solution

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-ColorOutput "Azure Virtual Enclave Cleanup" "Cyan"
    Write-ColorOutput "=============================" "Cyan"
    
    # Check if logged in to Azure
    try {
        $account = az account show --query "user.name" -o tsv 2>$null
        Write-ColorOutput "✓ Logged in as: $account" "Green"
    }
    catch {
        Write-ColorOutput "✗ Not logged in to Azure. Please run 'az login'" "Red"
        exit 1
    }
    
    # Check if resource group exists
    $rgExists = az group exists --name $ResourceGroupName
    if ($rgExists -eq "false") {
        Write-ColorOutput "✗ Resource group '$ResourceGroupName' does not exist" "Red"
        exit 1
    }
    
    # Get resource group details
    $rgInfo = az group show --name $ResourceGroupName --query "{location:location, tags:tags}" -o json | ConvertFrom-Json
    Write-ColorOutput "Found resource group: $ResourceGroupName" "Yellow"
    Write-ColorOutput "  Location: $($rgInfo.location)" "White"
    
    # List resources in the group
    Write-ColorOutput "Getting resources in resource group..." "Yellow"
    $resources = az resource list --resource-group $ResourceGroupName --query "[].{name:name, type:type}" -o json | ConvertFrom-Json
    
    if ($resources.Count -eq 0) {
        Write-ColorOutput "No resources found in resource group" "Yellow"
    }
    else {
        Write-ColorOutput "Resources to be deleted:" "Red"
        foreach ($resource in $resources) {
            Write-ColorOutput "  - $($resource.name) ($($resource.type))" "White"
        }
        Write-ColorOutput "Total resources: $($resources.Count)" "Yellow"
    }
    
    # Confirmation prompt
    if (-not $Force) {
        Write-ColorOutput "" "White"
        Write-ColorOutput "WARNING: This will permanently delete all resources in the resource group!" "Red"
        $confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
        
        if ($confirmation.ToLower() -ne "yes") {
            Write-ColorOutput "Cleanup cancelled by user" "Yellow"
            exit 0
        }
    }
    
    # Delete resource group
    Write-ColorOutput "Deleting resource group '$ResourceGroupName'..." "Yellow"
    Write-ColorOutput "This may take several minutes..." "White"
    
    az group delete --name $ResourceGroupName --yes --no-wait
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "✓ Cleanup initiated successfully!" "Green"
        Write-ColorOutput "Note: Deletion is running in the background and may take several minutes to complete" "Yellow"
        Write-ColorOutput "You can check the status in the Azure Portal" "White"
    }
    else {
        Write-ColorOutput "✗ Cleanup failed!" "Red"
        exit 1
    }
}
catch {
    Write-ColorOutput "Script failed: $($_.Exception.Message)" "Red"
    exit 1
}