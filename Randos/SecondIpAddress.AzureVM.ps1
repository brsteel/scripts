

$secondIpAddress = "10.0.0.5"
$netConfig = Get-NetIpConfiguration
$primaryIpAddress = Get-NetIPAddress -InterfaceIndex $netConfig.InterfaceIndex -AddressFamily IPv4
$dnsServerAddresses = (Get-DnsClientServerAddress -Interfaceindex 25 -AddressFamily IPv4).ServerAddresses
$defaultGateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -ExpandProperty "NextHop"
if ($primaryIpAddress.PrefixOrigin -eq "DHCP") {
    Set-NetIPInterface -Dhcp Disabled -InterfaceIndex $netConfig.InterfaceIndex
    New-NetIPAddress -IPAddress $primaryIpAddress.IPAddress -InterfaceAlias $primaryIpAddress.InterfaceAlias -AddressFamily IPv4 -PrefixLength $primaryIpAddress.PrefixLength -DefaultGateway $defaultGateway
    New-NetIPAddress -IPAddress $secondIpAddress -InterfaceAlias $primaryIpAddress.InterfaceAlias -AddressFamily IPv4 -PrefixLength $primaryIpAddress.PrefixLength 
    Set-DnsClientServerAddress -InterfaceIndex 25 -Addresses $dnsServerAddresses
}                 