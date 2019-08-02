$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
New-ItemProperty $RegPath "DefaultPassword" -Value "inlaYers84*foRgeries" -type String -Force
Remove-ItemProperty $RegPath "AutoLogonCount" -Force