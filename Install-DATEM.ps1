# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Create firewall rule for Sentinel Lock System
New-NetFirewallRule -DisplayName "Sentinel Protection Server" -Direction Inbound -Protocol -Profile Any TCP -Program "C:\Program Files (x86)\Common Files\SafeNet Sentinel\Sentinel Protection Server\WinNT\spnsrvnt.exe" -Action Allow
New-NetFirewallRule -DisplayName "Sentinel Protection Server" -Direction Inbound -Protocol UDP -Profile Any -Program "C:\Program Files (x86)\Common Files\SafeNet Sentinel\Sentinel Protection Server\WinNT\spnsrvnt.exe" -Action Allow

#Install DATEM
& $ScriptPathParent\Datem\Setup.exe /s /f1'"'$ScriptPathParent\Datem\setup.iss'"' | Out-Null

#Install ElevationDatabase
& $ScriptPathParent\ElevationDatabase\setup.exe /s /f1'"'$ScriptPathParent\ElevationDatabase\setup_ElevationDB.iss'"' | Out-Null


