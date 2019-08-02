# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Copy MinGW files to c:\
Copy-Item $ScriptPathParent\MinGW c:\ -Recurse -Force

#Add MinGW to the Path so that programs run correctly
$OldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$NewPath=$OldPath + ';C:\MinGW'
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $NewPath


