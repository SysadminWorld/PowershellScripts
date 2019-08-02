Remove-Item -Path 'C:\Program Files\Mozilla Firefox' -Recurse | Out-Null
Remove-Item -Path 'C:\Program Files (x86)\Mozilla Firefox' -Recurse | Out-Null

# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Install Updated Firefox
& $ScriptPathParent\'Firefox Setup 57.0.exe' -ms | Out-Null