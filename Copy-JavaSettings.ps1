
#Copy New Templates

# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

Copy-Item -Path $ScriptPathParent'\Sun' -Destination 'C:\Windows\Sun' -Force -Recurse | Out-Null


