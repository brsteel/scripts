# Azure Virtual Enclave Deployment Script
# This script deploys the Azure Virtual Enclave infrastructure using Bicep templates

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US 2",
    
    [Parameter(Mandatory=$false)]
    [string]$BaseName = "ave-dev",
    
    [Parameter(Mandatory=$false)]
    [int]$NumberOfCommunities = 2,
    
    [Parameter(Mandatory=$false)]
    [int]$NumberOfEnclavesPerCommunity = 2,
    
    [Parameter(Mandatory=$false)]
    [int]$NumberOfWorkloadsPerEnclave = 2,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to validate prerequisites
function Test-Prerequisites {
    Write-ColorOutput "Checking prerequisites..." "Yellow"
    
    # Check if Azure CLI is installed
    try {
        $azVersion = az version --output tsv --query '"azure-cli"' 2>$null
        Write-ColorOutput "✓ Azure CLI version: $azVersion" "Green"
    }
    catch {
        Write-ColorOutput "✗ Azure CLI not found. Please install Azure CLI." "Red"
        exit 1
    }
    
    # Check if Bicep is installed
    try {
        $bicepVersion = az bicep version 2>$null
        Write-ColorOutput "✓ Bicep installed: $bicepVersion" "Green"
    }
    catch {
        Write-ColorOutput "Installing Bicep..." "Yellow"
        az bicep install
    }
    
    # Check if logged in to Azure
    try {
        $account = az account show --query "user.name" -o tsv 2>$null
        Write-ColorOutput "✓ Logged in as: $account" "Green"
    }
    catch {
        Write-ColorOutput "✗ Not logged in to Azure. Please run 'az login'" "Red"
        exit 1
    }
}

# Function to set subscription
function Set-AzureSubscription {
    param([string]$SubId)
    
    if ($SubId) {
        Write-ColorOutput "Setting subscription to: $SubId" "Yellow"
        az account set --subscription $SubId
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "✗ Failed to set subscription" "Red"
            exit 1
        }
    }
    
    $currentSub = az account show --query "{name:name, id:id}" -o json | ConvertFrom-Json
    Write-ColorOutput "✓ Using subscription: $($currentSub.name) ($($currentSub.id))" "Green"
}

# Function to deploy the solution
function Deploy-Solution {
    param(
        [string]$DeploymentName = "ave-deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    )
    
    Write-ColorOutput "Starting deployment: $DeploymentName" "Yellow"
    Write-ColorOutput "Configuration:" "Cyan"
    Write-ColorOutput "  - Base Name: $BaseName" "White"
    Write-ColorOutput "  - Location: $Location" "White"
    Write-ColorOutput "  - Communities: $NumberOfCommunities" "White"
    Write-ColorOutput "  - Enclaves per Community: $NumberOfEnclavesPerCommunity" "White"
    Write-ColorOutput "  - Workloads per Enclave: $NumberOfWorkloadsPerEnclave" "White"
    
    $totalEnclaves = $NumberOfCommunities * $NumberOfEnclavesPerCommunity
    $totalWorkloads = $totalEnclaves * $NumberOfWorkloadsPerEnclave
    Write-ColorOutput "  - Total Enclaves: $totalEnclaves" "Yellow"
    Write-ColorOutput "  - Total Workloads: $totalWorkloads" "Yellow"
    
    # Prompt for admin password if not set in environment
    if (-not $env:ADMIN_PASSWORD) {
        $securePassword = Read-Host "Enter admin password for VMs" -AsSecureString
        $env:ADMIN_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }
    
    # Build deployment command
    $deployCmd = @(
        "az", "deployment", "sub", "create"
        "--name", $DeploymentName
        "--location", $Location
        "--template-file", "solution.bicep"
        "--parameters", "solution.bicepparam"
        "--parameters", "baseName=$BaseName"
        "--parameters", "location=$Location"
        "--parameters", "numberOfCommunities=$NumberOfCommunities"
        "--parameters", "numberOfEnclavesPerCommunity=$NumberOfEnclavesPerCommunity"
        "--parameters", "numberOfWorkloadsPerEnclave=$NumberOfWorkloadsPerEnclave"
    )
    
    if ($WhatIf) {
        $deployCmd += "--what-if"
        Write-ColorOutput "Running What-If deployment..." "Yellow"
    }
    else {
        Write-ColorOutput "Starting actual deployment..." "Yellow"
    }
    
    # Execute deployment
    & $deployCmd[0] $deployCmd[1..($deployCmd.Length-1)]
    
    if ($LASTEXITCODE -eq 0) {
        if (-not $WhatIf) {
            Write-ColorOutput "✓ Deployment completed successfully!" "Green"
            
            # Get deployment outputs
            Write-ColorOutput "Getting deployment outputs..." "Yellow"
            $outputs = az deployment sub show --name $DeploymentName --query "properties.outputs" -o json | ConvertFrom-Json
            
            if ($outputs) {
                Write-ColorOutput "Deployment Summary:" "Cyan"
                Write-ColorOutput "  - Resource Group: $($outputs.resourceGroupName.value)" "White"
                Write-ColorOutput "  - Total Resources Deployed:" "White"
                Write-ColorOutput "    * Communities: $($outputs.totalResources.value.communities)" "White"
                Write-ColorOutput "    * Enclaves: $($outputs.totalResources.value.totalEnclaves)" "White"
                Write-ColorOutput "    * Workloads: $($outputs.totalResources.value.totalWorkloads)" "White"
            }
        }
        else {
            Write-ColorOutput "✓ What-If completed successfully!" "Green"
        }
    }
    else {
        Write-ColorOutput "✗ Deployment failed!" "Red"
        exit 1
    }
}

# Main execution
try {
    Write-ColorOutput "Azure Virtual Enclave Deployment" "Cyan"
    Write-ColorOutput "=================================" "Cyan"
    
    Test-Prerequisites
    Set-AzureSubscription -SubId $SubscriptionId
    Deploy-Solution
    
    Write-ColorOutput "Script completed successfully!" "Green"
}
catch {
    Write-ColorOutput "Script failed: $($_.Exception.Message)" "Red"
    exit 1
}
finally {
    # Clear sensitive environment variables
    if ($env:ADMIN_PASSWORD) {
        Remove-Item Env:\ADMIN_PASSWORD -ErrorAction SilentlyContinue
    }
}