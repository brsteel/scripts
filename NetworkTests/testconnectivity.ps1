# Read the parameters from the JSON file
$parameters = Get-Content -Path 'params.json' | ConvertFrom-Json

# Assign the parameters to variables
$urllist = $parameters.urllist
$count = $parameters.count
$responseTimeout = $parameters.responseTimeout
$myipsite = $parameters.myipsite
$skipTracertTest = $parameters.skipTracertTest
$skipResponseTimeTest = $parameters.skipResponseTimeTest
$skipUploadFile = $parameters.skipUploadFile
$skipNslookupTest = $parameters.skipNslookupTest
$storageAccountName = $parameters.storageAccountName
$endPointSuffix = $parameters.endPointSuffix
$containerName = $parameters.containerName
$sasToken = $parameters.sasToken

#add upload to the URI string
$uriupload = "$($uri)upload/"
# Set the timeout to milliseconds for the response time test
$responseTimeout = $responseTimeout * 1000

#get local IP address of computer
$localIpAddress = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*" } | Select-Object -ExpandProperty IPAddress

#get the IP address that connects to the website (SNATE IP) if client is being NATed
$snatIpAddress = Invoke-WebRequest -Uri $myipsite
$snatIpAddress = $snatIpAddress -match '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' | Out-Null
$snatIpAddress = $matches[0]

#prep the connection string for the Azure Storage Account
$connectionStringTemplate = "BlobEndpoint=https://{0}.blob.{1}/;SharedAccessSignature={2}"
$connectionString = $connectionStringTemplate -f $storageAccountName, $endPointSuffix, $sasToken

# Encode the connection string and container name
$encodedConnectionString = [System.Web.HttpUtility]::UrlEncode($connectionString)
$encodedContainerName = [System.Web.HttpUtility]::UrlEncode($containerName)

# Append the connection string and container name to the URI
$uri = "$($uriupload)?connectionString=$($encodedConnectionString)&containerName=$($encodedContainerName)"

function logOutput {
    param(
        [Parameter(Mandatory=$true)]
        [PSObject]$OutputObject,

        [Parameter(Mandatory=$true)]
        [string]$logFile
    )

    # Convert the object to JSON and write it to the log file
    $OutputObject | ConvertTo-Json | Out-File -Append -FilePath $logFile
}

function uploadFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$uri,

        [Parameter(Mandatory=$true)]
        [string]$fileToUpload
    )

    # Create a multipart/form-data content
    Add-Type -AssemblyName System.Net.Http
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
    $httpClient = New-Object System.Net.Http.HttpClient
    $response = $httpClient.PostAsync($uri, $multipartContent).Result
    # Output the response
    $response
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
        
        #setup logFile location
        $logFile = "$env:USERPROFILE\Documents\NetworkTests-$hostname.log"
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
        logOutput -OutputObject $outputObject -logFile $logFile
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
            TRACERT.EXE -h 100 $hostName | Tee-Object -Variable traceRouteResult
            
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
                        $outputObject | Add-Member -Type NoteProperty -Name ("Hop " + ($counter - 2)) -Value $line    <# Action when all if and elseif conditions are false #>
                    }
                }
                $counter++
            }
            # Log the output
            logOutput -OutputObject $outputObject -logFile $logFile
}   
function performTestNetconnection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$hostName,
        [Parameter(Mandatory=$true)]
        [string]$logFile
    )
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
    logOutput -OutputObject $outputObject -logFile $logFile

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
    Write-Output "Testing response time to $url using WebRequest 100 times using $responseTimeout ms timeout"
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
    logOutput -OutputObject $outputObject -logFile $logFile
}   

foreach ($url in $urllist) 
{

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
}

if (!$skipUploadFile) {
# Upload the log file unless skipped
Write-Output "Uploading log file to Azure Storage Account"
uploadFile -uri $uri -fileToUpload $logFile
}