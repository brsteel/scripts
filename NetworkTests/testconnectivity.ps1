# Read the parameters from the JSON file
$parameters = Get-Content -Path 'params.json' | ConvertFrom-Json

# Assign the parameters to variables
$urlList = $parameters.urllist
$count = $parameters.count
$responseTimeout = $parameters.responseTimeout
$startMtuSize = $parameters.startMtuSize
$myIpSite = $parameters.myipsite
$skipTracertTest = $parameters.skipTracertTest
$tracertCount = $parameters.tracertCount
$skipResponseTimeTest = $parameters.skipResponseTimeTest
$skipUploadFile = $parameters.skipUploadFile
$skipNslookupTest = $parameters.skipNslookupTest
$sasUrl = $parameters.sasUrl

# Set the timeout to milliseconds for the response time test
$responseTimeout = $responseTimeout * 1000

#get local IP address of computer
$localIpAddress = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*" } | Select-Object -ExpandProperty IPAddress

#get the IP address that connects to the website (SNATE IP) if client is being NATed
$snatIpAddress = Invoke-WebRequest -Uri $myIpSite
$snatIpAddress = $snatIpAddress -match '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' | Out-Null
$snatIpAddress = $matches[0]

function UploadFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$sasUrl,

        [Parameter(Mandatory=$true)]
        [string]$logFile
    )

    if (-not (Test-Path -Path $logFile)) {
        Write-Error "File $logFile does not exist."
        return
    }

    $fileContent = Get-Content -Path $logFile -Raw

    try {
        $headers = @{
            'x-ms-blob-type' = 'BlockBlob'
        }

        # Split the SAS URL into the base URL and the SAS token
        $urlParts = $sasUrl -split '\?'

        $rawBlobName = Split-Path -Path $logFile -Leaf
        
        # Get the current date and time
        $currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"

        # Get the file extension
        $fileExtension = [IO.Path]::GetExtension($rawBlobName)

        # Get the filename without the extension
        $filenameWithoutExtension = [IO.Path]::GetFileNameWithoutExtension($rawBlobName)

        # Create the new filename by appending the date and time
        $blobName = "$filenameWithoutExtension-$currentDateTime$fileExtension"

        # Construct the blob URL by including the blob name in the base URL
        $blobUrl = "$($urlParts[0])/$($blobName)?$($urlParts[1])"

        Write-Output $blobUrl
        $response = Invoke-WebRequest -Uri $blobUrl -Method Put -Body $fileContent -ContentType 'application/octet-stream' -Headers $headers

        Write-Output $response

        if ($response.StatusCode -eq 201) {
            Write-Output "File uploaded successfully."
        } else {
            Write-Error "Failed to upload file. Status code: $($response.StatusCode)"
        }
    }
    catch {
        Write-Error "Failed to upload file: $_"
    }
}
function performNslookup {
    param(
        [Parameter(Mandatory=$true)]
        [string]$hostName,
        [Parameter(Mandatory=$true)]
        [string]$logFile
    )
        #setup host name
        [string]$hostName = $url -replace "https?://", ""
        
        #output the target name to the console
        Write-Output "Target: $hostName"
        
        #clean up any old log file with the same name
        if (Test-Path $logFile) { Remove-Item $logFile }
        
        #get the IP address of the target
        $ipAddress = [System.Net.Dns]::GetHostAddresses($hostName) | Select-Object -ExpandProperty IPAddressToString
        
        #output the local IP address, SNAT IP address, and target IP address to the console
        Write-Output "Client IP Address: $localIpAddress"
        Write-Output "Client SNAT IP Address: $snatIpAddress"
        Write-Output "Target IP Address: $ipAddress"
        
        #perform nslookup on target
        $nslookupResult = nslookup $hostName 2>&1
        
        #parse the nslookup result and output the authoritative DNS server and the DNS server address to the console    
        $serverLine = ($nslookupResult | Select-String -Pattern "Server:.*").Line
        $server = ($serverLine -split ":\s+")[1]
        Write-Output "Authoritative DNS Server: $server"
        $addressLine = ($nslookupResult | Select-String -Pattern "Address:.*").Line
        $address = ($addressLine -split ":\s+")[1].TrimEnd("`r")
        Write-Output "DNS Server Address: $address"
        
        # Create a custom object to store the logging output
        $outputObject = New-Object PSObject
        # Add the properties to the object for logging data
        $outputObject | Add-Member -Type NoteProperty -Name "Client IP Address" -Value $localIpAddress
        $outputObject | Add-Member -Type NoteProperty -Name "Client SNAT IP Address" -Value $snatIpAddress
        $outputObject | Add-Member -Type NoteProperty -Name "Target" -Value $hostName
        $outputObject | Add-Member -Type NoteProperty -Name "Target IP Address" -Value $ipAddress
        $outputObject | Add-Member -Type NoteProperty -Name "Authoritative DNS Server" -Value $server
        $outputObject | Add-Member -Type NoteProperty -Name "DNS Server Address" -Value $address
        # Log the output
        $OutputObject | ConvertTo-Json | Out-File -Append -FilePath $logFile
            <# Action to perform. You can use $ to reference the current instance of this class #>
}
function performTracertTest {
    param(
        [Parameter(Mandatory=$true)]
        [string]$hostName,
        [Parameter(Mandatory=$true)]
        [string]$logFile
    )
            #perform traceroute to target
            Write-Output "Tracing route to target."
            Write-Output "This may take a while..."
            Write-Output ""
            TRACERT.EXE -h $tracertCount $hostName | Tee-Object -Variable traceRouteResult
            
            # reset logging outputObject for traceroute logging
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
                        $outputObject | Add-Member -Type NoteProperty -Name ("Hop " + ($counter - 4)) -Value $line    <# Action when all if and elseif conditions are false #>
                    }
                }
                $counter++
            }
            # Log the output
            $OutputObject | ConvertTo-Json | Out-File -Append -FilePath $logFile
}   
function performTestNetconnection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$hostName,
        [Parameter(Mandatory=$true)]
        [string]$logFile
    )
    
    Write-Output "Testing network connection to $hostName on port 443."
    Write-Output "There is a known issue with the Test-NetConnection cmdLet that will keep its progress bar displaying persistently throughout the script. This does not affect the script's functionality."
    
    Start-Sleep 3

    #perform test-netconnection to target on port 443
    $testNetconnectionResult = Test-NetConnection -ComputerName $hostName -Port 443

    # reset logging outputObject for traceroute logging
    $outputObject = New-Object PSObject

    # Add the properties of the test-netconnection result to the output object
    foreach ($property in ($testNetconnectionResult | Get-Member -MemberType *Property).Name)
    {
        $outputObject | Add-Member -Type NoteProperty -Name $property -Value $testNetconnectionResult.$property
    }

    # Log the output
    $OutputObject | ConvertTo-Json | Out-File -Append -FilePath $logFile

    if ($testNetconnectionResult.TcpTestSucceeded -eq $false)
    {
        Write-Output "Test-NetConnection to $hostName on port 443 failed."
        Write-Output "Please check that any firewalls are not blocking port 443, and that you have IP connectivity to the listed FQDNs.."
        Write-Output "Terminating script, addtional tests will not be performed."
        exit
    }
}
function performResponseTimeTest {
    param(
        [Parameter(Mandatory=$true)]
        [string]$url,
        [Parameter(Mandatory=$true)]
        [string]$logFile,
        [Parameter(Mandatory=$true)]
        [int]$responseTimeout,
        [Parameter(Mandatory=$true)]
        [int]$count
    )
    #write to console that we are testing response time
    Write-Output "Testing response time to $url using WebRequest $count times using $responseTimeout ms timeout"
    Write-Output "This may take a while..."
    #get the count from passed in variable, or default from parameter block
    $responseCount = $count
    write-output "response count is $responseCount"
    
    # reset oubputObject for response time test logging
    $outputObject = New-Object PSObject
    # Loop through the response time test
    while ($responseCount -gt 0)
    {
        #slow the script a bit to avoid overloading the target
        Start-Sleep -Seconds 1
        # Create a web request and get the response time
        $request = [System.Net.WebRequest]::Create($url)
        $request.Timeout = $responseTimeout
        try {
            #capture the response time
            $startTime = Get-Date
            $response = $request.GetResponse()
            $endTime = Get-Date
            $responseTime = ($endTime - $startTime).TotalMilliseconds
            #write the response time to the console and to logging object
            Write-Output "Response time: $responseTime ms"
            $outputObject | Add-Member -Type NoteProperty -Name ("ResponseTime " + ($responseCount)) -Value "$responseTime ms"
            #close the response
            $response.Close()
        } 
        catch 
        {
            Write-Output "Timed out"
            $outputObject | Add-Member -Type NoteProperty -Name ("ResponseTime " + ($responseCount)) -Value "Timed out"
        }
        #decrement the counter
        $responseCount--
    }
    # Log the output
    $OutputObject | ConvertTo-Json | Out-File -Append -FilePath $logFile
}   
function testMtuSize {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Destination,

        [Parameter(Mandatory=$false)]
        [int]$StartMtuSize = 1200,

        [Parameter(Mandatory=$false)]
        [int]$MaxMtuSize = 1500,

        [Parameter(Mandatory=$false)]
        [int]$StepSize = 10
    )

    # reset oubputObject for response time test logging
    $outputObject = New-Object PSObject

    $mtuSize = $StartMtuSize

    while ($mtuSize -le $MaxMtuSize) {
        
        Write-Output "Testing MTU size $mtuSize"
        $pingResult = & ping.exe -f -l $mtuSize $Destination -n 1
        
        if ($pingResult -like "*Packet needs to be fragmented but DF set.*") {
            Write-Output "MTU size $mtuSize causes fragmentation."
            $outputObject | Add-Member -Type NoteProperty -Name "$mtusize" -Value "Fragmentation"
            break
        }
        else {
            $outputObject | Add-Member -Type NoteProperty -Name "$mtusize" -Value "Good"
        }

        $mtuSize += $StepSize
    }

    if ($mtuSize -gt $MaxMtuSize) {
        Write-Output "No fragmentation up to MTU size $MaxMtuSize."
    }
    # Log the output
    $OutputObject | ConvertTo-Json | Out-File -Append -FilePath $logFile
}

foreach ($url in $urllist) 
{

    #extract the hostname from the URL
    $tempObj = New-Object System.Uri($url)
    $hostname = $tempObj.Host

    #setup logFile location
    $logFile = "$env:USERPROFILE\Documents\NetworkTests-$hostname.log"

    if (!$skipTestNetconnection) 
    {
        performTestNetconnection -hostName $hostName -logFile $logFile
    }

    if (!$skipNslookupTest)
    {
        performNslookup -hostName $hostName -logFile $logFile
    }

    if (!$skipTracertTest) 
    {
        performTracertTest -hostName $hostName -logFile $logFile
    }   

    if (!$skipResponseTimeTest) 
    {
        performResponseTimeTest -url $url -logFile $logFile -responseTimeout $responseTimeout -count $count
    }   
    if (!$skipMtuSizeTest) 
    {
        testMtuSize -Destination $hostname -StartMtuSize $startMtuSize
    }   
}
if (!$skipUploadFile) {
    # Upload the log file unless skipped
    Write-Output "Uploading log file $logFile to Azure Storage Account"
    if (Test-Path $logFile) {
        $response = UploadFile -sasUrl $sasUrl -logFile $logFile
    }
    else {
        Write-Output "Log file does not exist"
    }
    
    if ($response.StatusCode -ne "201") {
        Write-Output $response
        Write-Output "Failed to upload log file to Azure Storage Account"
        Write-Output "Response status code: $($response.StatusCode)"
        Write-Output "Response status description: $($response.StatusDescription)"
        Write-Output "Response content: $($response.Content)"
        exit
    }
    else 
    {
        Write-Output "$logFile uploaded to Azure Storage Account"
    }
}
