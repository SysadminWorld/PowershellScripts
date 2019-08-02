# Set Execution Policy
#
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
#
#
# Set Automatic Login Settings
#
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  
New-ItemProperty -path $RegPath 'AutoAdminLogon' -Value '1' -type String -Force
New-ItemProperty -path $RegPath 'DefaultUsername' -Value 'ua\uaa_cwa_student' -type String  -Force
#New-ItemProperty -path $RegPath 'DefaultDomainName' -Value 'ua.ad.alaska.edu' -type String -Force
New-ItemProperty -path $RegPath 'DefaultDomainName' -Value "$env:computername" -type String -Force
New-ItemProperty -path $RegPath 'DefaultPassword' -Value 'DesktopSup2017' -type String -Force
New-ItemProperty -path $RegPath 'DefaultPassword' -Value 'DesktopSup2017' -type String -Force
Remove-ItemProperty -path $RegPath 'AutoLogonCount' -Force
#
# Script Complete