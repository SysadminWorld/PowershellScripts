# Set Automatic Login Settings
#
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  
New-ItemProperty -path $RegPath 'AutoAdminLogon' -Value '1' -type String -Force
New-ItemProperty -path $RegPath 'DefaultUsername' -Value 'uaa_mp_printrelease' -type String  -Force
New-ItemProperty -path $RegPath 'DefaultDomainName' -Value 'ua.ad.alaska.edu' -type String -Force
New-ItemProperty -path $RegPath 'DefaultPassword' -Value 'inlaYers84*foRgeries' -type String -Force
New-ItemProperty -path $RegPath 'DefaultPassword' -Value 'inlaYers84*foRgeries' -type String -Force
Remove-ItemProperty -path $RegPath 'AutoLogonCount' -Force
