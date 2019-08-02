#Copies the License file so that MatLab can install
$targetdirectory = "C:\Matlab"
 
if (!(Test-Path -path $targetdirectory)) {New-Item $targetdirectory -Type Directory}
Copy-Item -Path $PSSCriptRoot\network.lic -Destination $targetdirectory
Copy-Item -Path $PSSCriptRoot\40557433_done.txt -Destination $targetdirectory

# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Install Matlab
#& $ScriptPathParent\'setup.exe' -inputfile $ScriptPathParent\'installer_input - 307057.txt' | Out-Null

#Install Matlab
& $ScriptPathParent\'setup.exe' -inputfile $ScriptPathParent\'installer_input - 40557433.txt' | Out-Null

