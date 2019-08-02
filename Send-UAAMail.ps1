#This script is to send the mail from the outlook connector

# Install the 7-Zip module for use in compressing the logs folder.
Install-Module -Name 7Zip4PowerShell -WarningAction Ignore -Force | Out-Null

# Initialize the TS Environment
#$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$LogsDirectory = "c:\Windows\CCM\Logs\*"


# test to see if Archive folder exists
$TestPath = Test-Path -path c:\Archives
If ($TestPath) {
}
else {
$NewPath = New-Item -Path c:\Archive -ItemType Directory -Force
}
# Compress Log files for emailing
Compress-7Zip -Path c:\Windows\CCM\Logs -ArchiveFileName c:\Archive\logs.zip -Format Zip | Out-Null


$SMTPServer = "aspam-auth.uaa.alaska.edu"
$SMTPPort = "25"
$Make = (Get-WmiObject -Class:Win32_Computersystem).Manufacturer
$Model = (Get-WmiObject -Class:Win32_Computersystem).Model
[int]$Memory = ((Get-WmiObject -Class:Win32_Computersystem).TotalPhysicalMemory)/1gb
$SerialNumber = (Get-WmiObject -Class:Win32_BIOS).SerialNumber
[int]$Disk = ((Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 3").Size)/1gb
$MacAddress = (get-wmiobject win32_networkadapterconfiguration -filter "IPEnabled='True'").MACAddress
$link = "<a href='mailto:aa9dbc5e.O365.alaska.edu@amer.teams.ms'>@team</a>"

$From = "SCCM_Deployment@alaska.edu"
$To = "aa9dbc5e.O365.alaska.edu@amer.teams.ms"
$CC = "jyoakum@alaska.edu"
$Subject = "OS Deployment"
$Body = @"
<h1 style="color:MediumSeaGreen;">
<img src="http://uaa.alaska.edu//about/administrative-services/departments/information-technology-services/our-services/endpoint-management/_images/Failure.png" alt="Failure" align="right">
Upgrade Failure</h1>
<a href='mailto:aa9dbc5e.O365.alaska.edu@amer.teams.ms'>@Operating System Deployment Notifications</a>
<a href='mailto:jyoakum@alaska.edu'>John Yoakum</a>
<p>The following device has failed the Windows Upgrade Workflow. See Attached logs for troubleshooting.</p>
<p></p>
<p>The Computer $env:COMPUTERNAME has failed to upgrade properly.</p>
<ul>
  <li>Vendor:  $Make</li>
  <li>Model:  $Model</li>
  <li>Memory: $Memory GB</li>
  <li>Hard Drive Size: $disk GB</li>
  <li>MAC Address: $MacAddress</li>
  <li>SerialNumber: $SerialNumber</li>
</ul>
"@
$Attachment = "C:\Archive\Logs.zip"

$secpasswd = ConvertTo-SecureString 'sq}DD3"j7,`,/{B%b&q6+$cvPSsTvRUQ#r@R<Fwv' -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("ua\uaa_wsdeploy", $secpasswd)

Send-MailMessage -From $From -to $To -Subject $Subject -Cc $CC -BodyAsHtml $Body -SmtpServer $SMTPServer -port $SMTPPort -Credential $mycreds -Attachments $Attachment