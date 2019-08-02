# Static variables
$SecretKey = "3d6569a0-1e5d-4318-83fc-2ce3d2330d9d"
$CollectionID = "P0100071"

# Construct web service proxy
try {
    $URI = "http://CM01.lab.local/ConfigMgrWebService/ConfigMgr.asmx"
    $WebService = New-WebServiceProxy -Uri $URI -ErrorAction Stop
}
catch [System.Exception] {
    Write-Warning -Message "An error occured while attempting to calling web service. Error message: $($_.Exception.Message)" ; break
}

# Import computer information
try {
    $WebService.RemoveCMLastPXEAdvertisementForCollection($SecretKey, $CollectionID)
}
catch [System.Exception] {
    Write-Warning -Message "An error occured while attempting to calling web service. Error message: $($_.Exception.Message)" ; break
}