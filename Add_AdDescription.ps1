<#
.SYNOPSIS
    Adds SPPS, date of install, and user that installed software onto compter object description for querying for blling
.DESCRIPTION
    This script will add/append a description to the AD object for the local computer that this was ran on that will include the
    name of the software (SPSS), the date it was installed and the username of the person that installed it for tracking purposes.
.EXAMPLE
    .\Set-SPSSInstall.ps1
.NOTES
    FileName:    Set-SPSSInstall.ps1
    Author:      John Yoakum
    Created:     2018-02-27
    
    Version history:
    1.0.0 - (2018-02-27) Script created

#>

# Get Current Environment Information
#$CurrentDate = get-date -Format d
#$CurrentUserName = $env:USERNAME
$ComputerName = $env:COMPUTERNAME

$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment


# Query web service to retrieve current info stored in description field of computer account
$URI = 'http://anc-sccm-dist00.ua.ad.alaska.edu/kosterws/ad.asmx'
$WebService = New-WebServiceProxy -Uri $URI -ErrorAction Stop
$CurrentDesc = $WebService.GetComputerAttribute($ComputerName, 'Description')

# Set information to be added to description field
#$Description = "SPSS,$CurrentDate,$CurrentUserName"
$Description = $tsenv.Value("ADNotes")

# Determine if Current Description has information in it or not and append data to existing
If ($CurrentDesc -eq '') {
    $Description = $Description
}
else {
    $Description = $Description + ":" + $CurrentDesc
}

# Call web service to write data to description field in AD
$URI = 'http://anc-sccm-dist00.ua.ad.alaska.edu/ConfigMgrWebService/ConfigMgr.asmx'
$SecretKey = 'e64f0919-270a-4a20-bd0d-57be1d86befa'
$WebService = New-WebServiceProxy -Uri $URI -ErrorAction Stop
$WebService.SetADComputerDescription($SecretKey, $ComputerName, $Description)
