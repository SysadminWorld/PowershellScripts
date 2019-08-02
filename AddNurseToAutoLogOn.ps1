$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"  
Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String  
Set-ItemProperty $RegPath "DefaultUsername" -Value ".\Nurse" -type String  
Set-ItemProperty $RegPath "DefaultPassword" -Value "" -type String