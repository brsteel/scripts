$publicIpName = "APIMAddress"
$rgName = "BrookeSteele-vWANTest"
$allocation = "Static"
$location = "usgovvirginia"
$zone = 1
$sku = "standard"
$publicIp = New-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $rgName -AllocationMethod $allocation -DomainNameLabel $dnsPrefix -Location $location -Zone $zone -Sku $sku