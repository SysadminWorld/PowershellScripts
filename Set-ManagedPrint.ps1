# Set Execution Policy
#
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
#
#Add a local user account for print release
$computername = $env:computername
$username = 'uaa_mp_printrelease'
$password = 'inlaYers84*foRgeries'
$desc = 'Local Admin Account for Print Release'
$computer = [ADSI]"WinNT://$computername,computer"
$user = $computer.Create("user", $username)
$user.SetPassword($password)
$user.Setinfo()
$user.description = $desc
$user.setinfo()
$user.UserFlags = 65536
$user.SetInfo()
$group = [ADSI]("WinNT://$computername/administrators,group")
$group.add("WinNT://$username,user")
#
#Add a local user account for student
$computername = $env:computername
$username = 'mpt'
$password = 'M@1ntMPs'
$desc = 'Local Admin Account for Print Release'
$computer = [ADSI]"WinNT://$computername,computer"
$user = $computer.Create("user", $username)
$user.SetPassword($password)
$user.Setinfo()
$user.description = $desc
$user.setinfo()
$user.UserFlags = 65536
$user.SetInfo()
$group = [ADSI]("WinNT://$computername/administrators,group")
$group.add("WinNT://$username,user")

# Set Pharos Station Registry Settings
$RegPath = "HKLM:\SOFTWARE\WOW6432Node\Pharos\Database Server"  
New-ItemProperty $RegPath "Host Address" -Value "$env:computername" -Propertytype String -Force

# Set Automatic Login Settings
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  
New-ItemProperty -path $RegPath 'AutoAdminLogon' -Value '1' -type String -Force
New-ItemProperty -path $RegPath 'DefaultUsername' -Value 'uaa_mp_printrelease' -type String  -Force
New-ItemProperty -path $RegPath 'DefaultDomainName' -Value 'ua.ad.alaska.edu' -type String -Force
#New-ItemProperty -path $RegPath 'DefaultDomainName' -Value "$env:computername" -type String -Force
New-ItemProperty -path $RegPath 'DefaultPassword' -Value 'inlaYers84*foRgeries' -type String -Force
New-ItemProperty -path $RegPath 'DefaultPassword' -Value 'inlaYers84*foRgeries' -type String -Force
Remove-ItemProperty -path $RegPath 'AutoLogonCount' -Force
#
# Set Pharos Shell Startup for Auto-Login User
#
#   Load ntuser.dat
#
#reg load HKU\managedprint c:\users\uaa_mp_printrelease\NTUSER.DAT
#
# Create a new key, close the hadle, and trigger garbage collection
#
#$result = New-ItemProperty -Path 'Registry::HKEY_USERS\managedprint\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' "Shell" -Value "C:\Program Files (x86)\Pharos\Bin\Pstation.exe" -PropertyType String -Force
#$result.Handle.Close()
#[gc]::Collect()
#
#Unload ntuser.dat
#
#reg unload HKU\managedprint
#
# Script Complete

#Copy Local Group Policy to computer
Copy-Item "$PSScriptRoot\grouppolicy\*" -Destination "C:\Windows\System32\grouppolicy" -Recurse -Force

#Copy igfxEM Module to new computer.
Copy-Item "$PSScriptRoot\igfxEM.exe" -Destination "C:\Windows\System32\" -Recurse -Force