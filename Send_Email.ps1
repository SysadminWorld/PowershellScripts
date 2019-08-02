$Make = (Get-WmiObject -Class:Win32_Computersystem).Manufacturer
$Model = (Get-WmiObject -Class:Win32_Computersystem).Model
[int]$Memory = ((Get-WmiObject -Class:Win32_Computersystem).TotalPhysicalMemory)/1gb
$SerialNumber = (Get-WmiObject -Class:Win32_BIOS).SerialNumber
[int]$Disk = ((Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 3").Size)/1gb
$MacAddress = (get-wmiobject win32_networkadapterconfiguration -filter "IPEnabled='True'").MACAddress

$OSDSENDMAILSMTPSERVER = "smtp.gmail.com"
$SMTPPort = "587"

$From = "jyoakum2013@gmail.com"
$To = "jyoakum@alaska.edu"
$Subject = "Notification from the OS Deployment solution"
$Body = @"
This is a notification from the OS Deployment solution.

The Computer $env:COMPUTERNAME is has been deployed
TaskSequenceName: $TSEnv:TASKSEQUENCENAME
Vendor:  $Make
Model:  $Model
Memory: $Memory GB
Hard Drive Size: $disk GB
MAC Address: $MacAddress
SerialNumber: $SerialNumber
"@

$Username = "jyoakum2013@gmail.com"
$Password = ConvertTo-SecureString -String "J102275y" -AsPlainText -Force
$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $Username, $Password

Send-MailMessage -Body $Body -From $From -SmtpServer $OSDSENDMAILSMTPSERVER -Subject $Subject -UseSsl -To $To -Port $SMTPPort -Credential $Credential

