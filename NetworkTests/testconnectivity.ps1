[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string[]]$urllist,
    [Parameter()]
    [int]$count = 100,
    [Parameter()]
    [float]$responseTimeout = 5,
    [switch]$skipTracertTest,
    [switch]$skipResponseTimeTest,
    [switch]$skipuploadFile
)

# Set the timeout to milliseconds for the response time test
$responseTimeout = $responseTimeout * 1000
#get local IP address of computer
$localIpAddress = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*" } | Select-Object -ExpandProperty IPAddress

function uploadFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$uri,

        [Parameter(Mandatory=$true)]
        [string]$fileToUpload
    )

    # Create a multipart/form-data content
    $multipartContent = New-Object System.Net.Http.MultipartFormDataContent
    $fileStream = [System.IO.FileStream]::new($fileToUpload, [System.IO.FileMode]::Open)
    $fileHeader = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue("form-data")
    $fileHeader.Name = "networktest"
    $fileHeader.FileName = [System.IO.Path]::GetFileName($fileToUpload)
    $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
    $fileContent.Headers.ContentDisposition = $fileHeader
    $fileContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream")
    $multipartContent.Add($fileContent)

    # Send the POST request
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $multipartContent

    # Output the response
    $response
}

function logOutput {
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]$OutputObject,

        [Parameter(Mandatory=$true)]
        [string]$Logfile
    )

    # Convert the object to JSON and write it to the log file
    $OutputObject | ConvertTo-Json | Out-File -Append -FilePath $Logfile
}

foreach ($url in $urllist) 
{
    try 
        {    
            #setup host name
            [string]$hostName = $url -replace "https?://", ""
            Write-Output "Target: $hostName"
            $logfile = "$env:USERPROFILE\Documents\NetworkTests-$hostname.log"
            if (Test-Path $logfile) { Remove-Item $logfile }
            #get DNS resolution information
            $ipAddress = [System.Net.Dns]::GetHostAddresses($hostName) | Select-Object -ExpandProperty IPAddressToString
            Write-Output "Client IP Address: $localIpAddress"
            Write-Output "Target IP Address: $ipAddress"
            $nslookupResult = nslookup $hostName 2>&1
            
            $serverLine = ($nslookupResult | Select-String -Pattern "Server:.*").Line
            $server = ($serverLine -split ":\s+")[1]
            Write-Output "Authoritative DNS Server: $server"
            $addressLine = ($nslookupResult | Select-String -Pattern "Address:.*").Line
            $address = ($addressLine -split ":\s+")[1].TrimEnd("`r")
            Write-Output "DNS Server Address: $address"
            
            # Create a custom object
            $outputObject = New-Object PSObject
            $outputObject | Add-Member -Type NoteProperty -Name "Client IP Address" -Value $localIpAddress
            $outputObject | Add-Member -Type NoteProperty -Name "Target" -Value $hostName
            $outputObject | Add-Member -Type NoteProperty -Name "Target IP Address" -Value $ipAddress
            $outputObject | Add-Member -Type NoteProperty -Name "Authoritative DNS Server" -Value $server
            $outputObject | Add-Member -Type NoteProperty -Name "DNS Server Address" -Value $address
            # Log the output
            logOutput -OutputObject $outputObject -Logfile $logfile
        
            if (!$skipTracertTest) 
            {
                #perform traceroute to target
                Write-Output "Tracing route to target."
                Write-Output "This may take a while..."
                Write-Output ""
                TRACERT.EXE -h 100 $hostName | Tee-Object -Variable traceRouteResult
                # reset oubputObject for traceroute
                $outputObject = New-Object PSObject
                
                # Parse the output of the tracert command and add it to the output object
                $counter = 1
                foreach ($line in $traceRouteResult)
                {
                    if ($counter -gt 4) 
                    {
                        if (($line -eq "") -or ($line -like "*Trace Complete*")) 
                        { 
                            continue 
                        }
                        else 
                        {
                            $outputObject | Add-Member -Type NoteProperty -Name ("Hop " + ($counter - 2)) -Value $line    <# Action when all if and elseif conditions are false #>
                        }
                    }
                    $counter++
                }
                # Log the output
                logOutput -OutputObject $outputObject -Logfile $logfile
            }   
        
            if (!$skipResponseTimeTest) 
            {
                #perform response time test to target
                Write-Output "Testing response time to $url using WebRequest 100 times using $responseTimeout ms timeout"
                Write-Output "This may take a while..."
                $responseCount = $count
                # reset oubputObject for response time test
                $outputObject = New-Object PSObject
                while ($responseCount -gt 0)
                {
                    Start-Sleep -Seconds 1
                    $request = [System.Net.WebRequest]::Create($url)
                    $request.Timeout = $responseTimeout
                    try {
                        $startTime = Get-Date
                        $response = $request.GetResponse()
                        $endTime = Get-Date
                        $responseTime = ($endTime - $startTime).TotalMilliseconds
                        Write-Output "Response time: $responseTime ms"
                        $outputObject | Add-Member -Type NoteProperty -Name ("ResponseTime " + ($responseCount)) -Value "$responseTime ms"
                        $response.Close()
                    } catch {
                        Write-Output "Timed out"
                        $outputObject | Add-Member -Type NoteProperty -Name ("ResponseTime " + ($responseCount)) -Value "Timed out"
                    }
                    $responseCount--
                }
                # Log the output
                logOutput -OutputObject $outputObject -Logfile $logfile
            }   
        
        } 
    catch 
        {
            Write-Output "Error: $($_.Exception.Message)"
        }
    }
