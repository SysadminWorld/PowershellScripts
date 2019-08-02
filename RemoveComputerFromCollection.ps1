# Variables
$SecretKey = "<ENTER SECRET KEY>"
$CollectionIDs = @("P01000B1", "P010008D")

# Construct TSEnvironment object
try {
    $TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
}
catch [System.Exception] {
    Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object" ; exit 3
}

# Get OSDComputerName variable value
$OSDComputerName = $TSEnvironment.Value("OSDComputerName")

# Construct web service proxy
try {
    $URI = "http://server.domain.com/ConfigMgrWebService/ConfigMgr.asmx"
    $WebService = New-WebServiceProxy -Uri $URI -ErrorAction Stop
}
catch [System.Exception] {
    Write-Warning -Message "An error occured while attempting to calling web service. Error message: $($_.Exception.Message)" ; exit 2
}

# Remove computer from each collection in collections variable
foreach ($CollectionID in $CollectionIDs) {
    Write-Output -InputObject "Attempting to remove device '$($OSDComputerName)' from CollectionID: $($CollectionID)"
    $Invocation = $WebService.RemoveCMDeviceFromCollection($SecretKey, $OSDComputerName, $CollectionID)
    switch ($Invocation) {
        $true {
            $ExitCode = 0
        }
        $false {
            $ExitCode = 1
        }
    }
}

# Exit script
exit $ExitCode