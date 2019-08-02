<#         
    .NOTES
===========================================================================
    Created with: SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.139     
    Created by:   Terence Beggs
    Organization: SCConfigMgr
    Filename:     Push-OSDNotification.ps1      
===========================================================================
    .DESCRIPTION
       	This uses the PushOver notification service   

    .SOCIAL
        Twitter : @terencebeggs
        Blog : https://www.scconfigmgr.com

    .CHANGELOG
        Version 1.0
        Version 1.1 - added _SMSTSPackageName and _SMSTSLogPath(removed)
        Version 1.2 - added bios, make, model etc
        Version 1.3 - Script clean up
   	
    .EXAMPLE
        Change the variables as needed
Send-Pushover -Message "<h4 style=color:blue;>$env:COMPUTERNAME</h4> <p><b>$TS</b> has completed successfully at <b>$DateTime</b></p> <p><b>IPAddress:</b>$IPAddress </p> <p>IPAddress:$IPAddress </p>" -Token  -User -MessageTitle "OSD Completed Successfully" -SendAsHTML -URL "\\Server\contentlib$\Logs\$env:COMPUTERNAME" -URLTitle "Logs Location"
#>

# Optional for using with Task Sequence Var 
# $TSenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

$DriveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceId='C:'"
$PSCustomObject = [PSCustomObject]@{
  DateTime 		= (Get-Date -Format g)
  Time			= (Get-Date -format HH:mm)
  Make			= (Get-WmiObject -Class Win32_BIOS).Manufacturer
  Model			= (Get-WmiObject -Class Win32_ComputerSystem).Model
  ComputerName	= (Get-WmiObject -Class Win32_ComputerSystem).Name
  SerialNumber	= (Get-WmiObject win32_bios).SerialNumber
  IPAddress		= (Get-WmiObject win32_Networkadapterconfiguration | Where-Object{ $_.ipaddress -notlike $null }).IPaddress | Select-Object -First 1
  Drive			= $DriveInfo | Select-Object -ExpandProperty DeviceID
  DiskSize		= ($DriveInfo.Size/1GB -as [int]).ToString()
  FreeSpace		= [math]::Round($DriveInfo.Freespace/1GB, 2)
}

# Where the logs are stored at the end of the TS
#$URL = "\\server\contentlibrary$\Logs\$env:COMPUTERNAME"

# URL Title
#$URLTitle = "$Name Logs"

# API location
$uri = "https://api.pushover.net/1/messages.json"

# Combine drive info to string
$DiskInfo = "Drive={0} DiskSize GB={1} FreeSpace GB={2}" -f $PSCustomObject.Drive, $PSCustomObject.DiskSize, $PSCustomObject.FreeSpace

# Passes the parameters to Invoke-RestMethod
$parameters = @{
  # Message Title
  title	= "Windows Upgrade FAILED"
  # Send as Html
  html	= "1"
  # Device or Device Group Key
  token	= "adigk7pc9xnb7d877fb3umyt2ne9ia"
  # User Key
  user	= "u8yydkcu8wshyb6e7jdfom7zxpdx1g"
  # Url title appears at the bottom
  #url_title = $URLTitle
  #url		= $URL
  # Message Contents
  message   = "<p>Warning
    Operating System Upgrade <strong><span style=color:red>FAILED</span></strong> 
  on computer: <span style=color:green><strong>$env:COMPUTERNAME</strong></span>
 
    <span style=color:blue><strong>Deployment Details :</strong></span>
    <strong>Computer name: </strong>   $($PSCustomObject.ComputerName) 
    <strong>Time Finished: </strong>  $($PSCustomObject.DateTime)
    <strong>IP: </strong> $($PSCustomObject.IPAddress)
    <strong>Make: </strong> $($PSCustomObject.Make)
    <strong>Model: </strong>  $($PSCustomObject.Model)
    <strong>Serial: </strong>  $($PSCustomObject.SerialNumber)
    <strong>Device Info: </strong>  $DiskInfo  
    </span>
</p>"
}

$parameters | Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/x-www-form-urlencoded'