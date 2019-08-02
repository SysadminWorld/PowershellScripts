# Variables
$SecretKey = "<ENTER SECRET KEY>"
$CollectionVariableName = "OSDOfficeLocation"

# Construct TSEnvironment object
try {
    $TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
}
catch [System.Exception] {
    Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object" ; exit 3
}

# Get OSDComputerName variable value
$OSDComputerName = $TSEnvironment.Value("OSDComputerName")

# Get collection variable value
$CollectionVariableValue = $TSEnvironment.Value($CollectionVariableName)

# Construct web service proxy
try {
    $URI = "http://server.domain.com/ConfigMgrWebService/ConfigMgr.asmx"
    $WebService = New-WebServiceProxy -Uri $URI -ErrorAction Stop
}
catch [System.Exception] {
    Write-Warning -Message "An error occured while attempting to calling web service. Error message: $($_.Exception.Message)" ; exit 2
}

# Determine the OU based upon collection variable value
switch ($CollectionVariableValue) {
    "NewYork" {
        $OU = "OU=Computers,OU=New York,OU=Office,DC=domain,DC=com"
    }
    "Chicago" {
        $OU = "OU=Computers,OU=Chicago,OU=Office,DC=domain,DC=com"
    }
}

# Move computer to new organization unit
$Invocation = $WebService.SetADOrganizationalUnitForComputer($SecretKey, $OU, $OSDComputerName)
switch ($Invocation) {
    $true {
        exit 0
    }
    $false {
        exit 1
    }
}