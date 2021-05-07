$host.UI.RawUI.BufferSize = new-object System.Management.Automation.Host.Size(600,0) 
$domain=($ENV:Computername).Split("-")[0]
$certPairs = @(
    ("DC", "AzureMonitor.AzureMonitor"),
    ("DC", "MA"),
    ("ERCS", "ECEServiceSecretEncryption"),
    ("ERCS", "IbcStorageAccountEncryption"),
    ("WAS", "MetricsAdmin"),
    ("WAS", "MetricsClient")
)

# As these VMs are described completely inaccessible, these attempts may not work
$certPairsAttempt =  @(
    ("ACS", "AzureMonitor.AzureMonitor"),
    ("ACS", "AzureMonitor.SRP"),
    ("XRP", "AzureMonitor.NRP"),
    ("XRP", "ComputeProviderEncryption"),
    ("XRP", "ComputeProviderStorageAccountEncryption"),
    ("XRP", "AzureMonitor.SRP"),
    ("XRP", "AzKVInternal Bootstrap Key"),
    ("XRP", "NetworkProviderEncryption"),
    ("XRP", "NetworkProviderStorageAccountEncryption"),
    ("XRP", "UpdateProviderStorageAccountEncryption"),
    ("XRP", "MetricsClient"),
    ("XRP", "AzKV Naming Service Configuration Encryption")
)

function Get-CertExpirationDateTime
{
    Param(
        [string] $Domain,
        [Object] $CertPairs
    )

    foreach ($pair in $CertPairs)
    {
        $computerNames = @()
        for ($i=1; $i -lt 3; $i++)
        {
            $computerNames += "$Domain-$($pair[0])0$i"
        }
        
        Invoke-Command -ComputerName $computerNames -ArgumentList $pair[1] -ErrorAction Continue -ScriptBlock {
            Param([string]$CNName)
            Get-ChildItem -Path "cert:\\LocalMachine\My" | Where-Object {$_.Subject -like "*$CNName*"} | Select-Object Subject, NotAfter
        }
    }
}

Get-CertExpirationDateTime -Domain $domain -CertPairs $certPairs|sort notafter|FT -autosize
Get-CertExpirationDateTime -Domain $domain -CertPairs $certPairsAttempt|sort notafter|FT -autosize 
