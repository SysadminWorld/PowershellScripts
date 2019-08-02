#Import-Module "C:\MININT\Modules\Microsoft.BDD.TaskSequenceModule"
#Import-Module "C:\MININT\Modules\ZTIUtility"

$SMTPPort = "587"
$Username = "jyoakum2013@gmail.com"
$Password = "J102275y"
#74.125.25.109 - smtp.gmail.com
$OSDSENDMAILSMTPSERVER = "smtp.gmail.com"

$From = "OSDDeployment@uaa.alaska.edu"
$To = "itsdesktop@uaa.alaska.edu"
$Subject = "Notification from the OS Deployment solution"
$Body = @"
This is a notification from the OS Deployment solution.

The Computer $env:COMPUTERNAME is has been deployed
TaskSequenceName: $TSEnv:TASKSEQUENCENAME
Vendor :$TSEnv:Make
Model: $TSEnv:Model
Memory: $TSEnv:Memory Megabyte
SerialNumber: $TSEnv:SerialNumber
"@

$SMTP = new-object System.Net.Mail.SmtpClient($OSDSENDMAILSMTPSERVER, $SMTPPort)
$SMTP.EnableSSL = $true
$SMTP.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
$SMTP.Send($From, $To, $subject, $body)
