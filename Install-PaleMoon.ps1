# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Install Palemoon Browser
& $ScriptPathParent\palemoon-28.1.0.win64.installer.exe -ms -ma | Out-Null

#Copy Preferences Files to machine
Copy-Item $ScriptPathParent\"AppData Stuff\Local\Moonchild Productions" -Destination "C:\Users\Default\AppData\Local" -Recurse -Force
Copy-Item $ScriptPathParent\"AppData Stuff\Roaming\Moonchild Productions" -Destination "C:\Users\Default\AppData\Roaming" -Recurse -Force

#Rename the Desktop Shortcut for Palemoon Browser
Rename-Item -Path "C:\Users\Public\Desktop\Pale Moon.lnk" -NewName "Guest Research.lnk"
