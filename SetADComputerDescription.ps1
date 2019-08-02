﻿# Variables
$SecretKey = "<ENTER SECRET KEY>"
$ComputerDescription = "Install date: $((Get-Date).ToShortDateString())"

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

# Add computer to group
$Invocation = $WebService.SetADComputerDescription($SecretKey, $OSDComputerName, $ComputerDescription)
switch ($Invocation) {
    $true {
        exit 0
    }
    $false {
        exit 1
    }
}