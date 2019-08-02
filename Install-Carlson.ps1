# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Install Carlson 2017
& $ScriptPathParent\'Carlson2017_64bit.exe' /s /f1'"'$ScriptPathParent\'carlson.iss"' /f2'"c:\windows\temp\Carlson.log"' | Out-Null

[Environment]::SetEnvironmentVariable("LSFORCEHOST", "anc-licensing05.ua.ad.alaska.edu", "Machine")
