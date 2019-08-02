<#
# script to copy some files before kicking off Upgrade.HTA
# Niall Brady 2019/01/06 windows-noob.com
#>

$Logfile = "C:\ProgramData\Windows10RequiredUpgradeStart-Upgrade.log"

Function LogWrite
{
   Param ([string]$logstring)
   Try
{
    $a = Get-Date
    $logstring = $a,$logstring
    Add-content $Logfile -value $logstring -ErrorAction silentlycontinue
}
Catch
{
    $logstring="Invalid data encountered"
    Add-content $Logfile -value $logstring
}
   write-host $logstring
}


#Add-Type –AssemblyName System.Windows.Forms

LogWrite "Starting the [Start-Upgrade] script... "
LogWrite "Copying files to....$env:temp " 
$files = @("Upgrade.hta","Banner.png","wrapper.ps1")

# copy some files, exit with exit code 99 if a problem copying any of them

foreach ($file in $files) {
LogWrite "about to copy $file"
write-host "copying .\$file"
$file = ".\$file"
copy-item $file -Destination $env:temp
}

LogWrite "launching '$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe $env:temp\wrapper.ps1'" 
Invoke-Expression "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe $env:temp\wrapper.ps1"

$?
LogWrite "finished with $env:temp\wrapper.ps1" 
LogWrite "LastExitCode from $env:temp\wrapper.ps1 was $LASTEXITCODE"
if ($LASTEXITCODE -eq 99)
{
    LogWrite "returning exit code 99 to System Environment"
    [System.Environment]::Exit(99)
   
}
LogWrite "Exiting script." 

