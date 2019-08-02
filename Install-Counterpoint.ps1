# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Install Counterpointer
& $ScriptPathParent\installcounterpointersite.exe /SP- /VERYSILENT /NORESTART | Out-Null

#Copy Preferences File to machine
Copy-Item $ScriptPathParent\"Counterpointer Preferences" "C:\Users\Public\Documents\Counter Preferences" -Force
