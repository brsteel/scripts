#login to Azure via POSH
$resourceGroupName = "BrookeSteele-vWANTest" #specify target resource group name that will contain the route table, ideally, the same RG that contains the vNet to which it will be attached
$routeTableName = "bsteeletestrt" #specify the name of the route table to be created
$azureRegion = "usgovarizona" #specify the region that will contain the route table

# https://docs.microsoft.com/en-us/azure/virtual-network/manage-route-table#:~:text=Create%20a%20route%20table%201%20On%20the%20Azure,Select%20Create%20to%20create%20your%20new%20route%20table.
$routeTable = New-AzRouteTable -ResourceGroupName $resourceGroupName -Name $routeTableName -Location $azureRegion -Confirm $true

$ipGroupList = (
    "APIManagement",
    "LogicApps",
    "LogicAppsManagement",
    "AzureTrafficManager",
    "AppService",
    "AppServiceManagement",
    "AzureConnectors"
)

$tags = Get-AzNetworkServiceTag -Location $azureRegion

foreach ($ipGroup in $ipGroupList) {

    $mydata = $tags.values | where {$_.name -like "$ipGroup"}
    $endpoints = $mydata.properties.addressprefixes
    $i = 0
    
    if ($ipGroup -like "*.*") {
        $ipGroupSplit = $ipGroup -split "[.]"
        $ipGroup = $ipGroupSplit[0]
    }

    foreach ($endpoint in $endpoints) {
        Add-AzRouteConfig -RouteTable $routeTable -Name "$ipGroup$i" -AddressPrefix $endpoint -NextHopType "Internet" -ErrorAction SilentlyContinue
        $i = $i + 1
    }
    Set-AzRouteTable -RouteTable $routeTable -ErrorAction Continue
}
