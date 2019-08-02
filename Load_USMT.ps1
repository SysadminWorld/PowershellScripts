# Stores the full path to this powershell script, works with all versions of PowerShell
# E.g. C:\Scripts\MyCoolScript.ps1
$ScriptPath =  $MyInvocation.MyCommand.Definition

# Stores the full path to the parent directory of this powershell script, works with all versions of PowerShell
# e.g. C:\Scripts
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

$StorePath = "\\anc-sccm-dist01.ua.ad.alaska.edu\State"
$LogPath = "\\anc-sccm-dist01.ua.ad.alaska.edu\USMTLogs"
& $ScriptPathParent\loadstate.exe $StorePath\$env:computername /i:$ScriptPathParent\miguser.xml /i:$ScriptPathParent\migapp.xml /all /v:5 /l:$LogPath\$env:computername\USMTLoad.log /progress:$LogPath\$env:computername\USMTLoadProgress.log /c | Out-Null
