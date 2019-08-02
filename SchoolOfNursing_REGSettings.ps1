# Set Execution Policy
#
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
#
#
#Add a local user account for nurse account
#$ComputerNumber = $env:computername.Substring($env:computername.length - 7, 7)
#$computername = $env:computername
$username = 'uaa_sontestingcarts'
<#
$password = 'Nur5ezr0ck!'
$desc = 'Local Account for School of Nursing'
$computer = [ADSI]"WinNT://$computername,computer"
$user = $computer.Create("user", $username)
$user.SetPassword($password)
$user.Setinfo()
$user.description = $desc
$user.setinfo()
$user.UserFlags = 65536
$user.SetInfo()
$group = [ADSI]("WinNT://$computername/users,group")
$group.add("WinNT://$username,user")
#>
# Set Automatic Login Settings
#
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  
New-ItemProperty -path $RegPath 'AutoAdminLogon' -Value '1' -type String -Force
New-ItemProperty -path $RegPath 'DefaultUsername' -Value 'uaa_sontestingcarts' -type String  -Force
New-ItemProperty -path $RegPath 'DefaultUsername' -Value 'uaa_sontestingcarts' -type String  -Force
New-ItemProperty -path $RegPath 'DefaultDomainName' -Value 'ua.ad.alaska.edu' -type String -Force
#New-ItemProperty -path $RegPath 'DefaultDomainName' -Value "$env:computername" -type String -Force
New-ItemProperty -path $RegPath 'DefaultPassword' -Value 'Nur5ezr0ck!' -type String -Force
New-ItemProperty -path $RegPath 'DefaultPassword' -Value 'Nur5ezr0ck!' -type String -Force
#Remove-ItemProperty -path $RegPath 'AutoLogonCount' -Force
#
# Script Complete