# Stores the full path to this powershell script, works with all versions of PowerShell
# E.g. C:\Scripts\MyCoolScript.ps1
$ScriptPath =  $MyInvocation.MyCommand.Definition

# Stores the full path to the parent directory of this powershell script, works with all versions of PowerShell
# e.g. C:\Scripts
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

# Stores the name of this powershell script, works with all versions of PowerShell
# e.g. MyCoolScript.ps1
$ScriptName = $MyInvocation.MyCommand.Name


# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + '(Elevated)'
   $Host.UI.RawUI.BackgroundColor = 'DarkBlue'
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo 'PowerShell';
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = 'runas';
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   #exit
   
   }
# Run your code that needs to be elevated here
#Write-Host -NoNewLine 'Press any key to continue...'
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
net use \\137.229.138.146\state Un1v3rcityC0nf1gMgr /user:ua\sccm-naa

$StorePath = "\\anc-sccm-dist01.ua.ad.alaska.edu\State"
$LogPath = "\\anc-sccm-dist01.ua.ad.alaska.edu\USMTLogs"
Start-Process -FilePath "$ScriptPathParent\loadstate.exe" -ArgumentList "$StorePath\$env:computername /i:$ScriptPathParent\miguser.xml /i:$ScriptPathParent\migapp.xml /all /v:5 /l:$LogPath\$env:computername\USMTLoad.log /progress:$LogPath\$env:computername\USMTLoadProgress.log /c" -Wait


#loadstate StorePath [/i:[Path\]FileName] [/v:VerbosityLevel] [/nocompress] [/decrypt /key:KeyString|/keyfile:[Path\]FileName] [/l:[Path\]FileName] [/progress:[Path\]FileName] [/r:TimesToRetry] [/w:SecondsToWait] [/c] [/all] [/ui:[[DomainName\]UserName]|LocalUserName] [/ue:[[DomainName\]UserName]|LocalUserName] [/uel:NumberOfDays|YYYY/MM/DD|0] [/md:OldDomain:NewDomain] [/mu:OldDomain\OldUserName:[NewDomain\]NewUserName] [/lac:[Password]] [/lae] [/q] [/config:[Path\]FileName] [/?|help]