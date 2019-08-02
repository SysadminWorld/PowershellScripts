# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Copies the RASPlib files so that MatLab can install
$targetdirectory = "C:\Matlab Add-Ins"
 
if (!(Test-Path -path $targetdirectory)) {New-Item $targetdirectory -Type Directory}

Copy-Item $ScriptPathParent\'RASPlib Files' $targetdirectory -Recurse -Force | Out-Null