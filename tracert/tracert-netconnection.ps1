$url = "portal.azure.us"  # Replace with your URL

Write-Host "Performing traceroute to $url"

$traceRoute = Test-NetConnection -ComputerName $url -TraceRoute | 
    Select-Object -ExpandProperty TraceRoute

foreach ($hop in $traceRoute) {
    $pingResult = Test-Connection -ComputerName $hop -Count 1 -ErrorAction SilentlyContinue
    Write-Host "$hop `t $($pingResult.ResponseTime)ms"
}
