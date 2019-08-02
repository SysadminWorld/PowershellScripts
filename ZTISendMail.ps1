#Import-Module "C:\MININT\Modules\Microsoft.BDD.TaskSequenceModule"
#Import-Module "C:\MININT\Modules\ZTIUtility"

$SMTPPort = "587"
$Username = "jyoakum2013@gmail.com"
$Password = "J102275y"
$NewMsg = new-object System.Net.Mail.MailMessage

$NewMsg.IsBodyHTML = $true
$NewMsg.From = "$tsenv:OSDSENDMAILFROM"
$NewMsg.To.Add($tsenv:OSDSendMailToPri)

$NewMsg.Subject = "Notification from the OS Deployment solution"
$NewMsg.Body = @"
This is a notification from the OS Deployment solution.

The Computer $env:COMPUTERNAME is has been deployed
TaskSequenceName: $TSEnv:TASKSEQUENCENAME
Vendor :$TSEnv:Make
Model: $TSEnv:Model
Memory: $TSEnv:Memory Megabyte
SerialNumber: $TSEnv:SerialNumber
"@
if ($tsenv:OSDSendMailIncludeBDDLog -eq "YES"){
    $AttachToMail001 = new-object Net.Mail.Attachment($tsenv:LOGPATH + "\BDD.log")
    $NewMsg.Attachments.Add($AttachToMail001)
}
$NewMsg
$SMTP = new-object System.Net.Mail.SmtpClient($tsenv:OSDSENDMAILSMTPSERVER,$SMTPPort);

$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
$SMTP.Send($NewMsg)

if ($OSDSendMailIncludeBDDLog -eq "YES"){$AttachToMail.Dispose()}

