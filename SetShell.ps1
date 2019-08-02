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
$RegPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
New-ItemProperty -Path $RegPath 'Shell' -Value 'C:\Program Files (x86)\Pharos\Bin\Pstation.exe' -Type String -Force