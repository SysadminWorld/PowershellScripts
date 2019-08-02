<#
# script to perform checks before and after launching the upgrade popup
# Niall Brady windows-noob.com 2019/1/6
#
#>

$Logfile = "C:\ProgramData\Windows10RequiredUgradeWrapper.log"
# change the next line to match the version of Windows 10 that you plan on forcefully upgrading to...using targetbuild for Windows 10 1803 (17134)
$TargetBuild = 17134
# what company to brand the registry with ? hkcu\software\$CompanyName
$CompanyName = "windowsnoob"

Function LogWrite
{
   Param ([string]$logstring)
   $a = Get-Date
   $logstring = $a,$logstring
   Try
{   
    Add-content $Logfile -value $logstring -ErrorAction silentlycontinue
}
Catch
{
    $logstring="Invalid data encountered"
    Add-content $Logfile -value $logstring
}
   write-host $logstring
}

Function DeleteRegKey($regpath, $regkey)
{
# Test if the reg key exists (returns $true or $false)

$regexists = Test-RegistryValue $regpath $regkey
LogWrite "Does the '$regpath' reg key exist ? $regexists"

# if it exists, delete it
if ($regexists)
    {logwrite "$regkey reg key exists."
    Remove-ItemProperty -path $regpath -name $regkey
    logwrite "Removed $regkey"
    }
    else
    {logwrite "$regkey reg key doesn't exist"
    }}


function Test-PendingReboot
{
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 #if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
     return $true
   }
 }catch{}
 
 return $false
}

function ShowMessage(){
$title="Windows 10 Required Upgrade"
$MessageBoxButtons="ok"
$MessageBoxIcon="Warning"
$MessageBoxDefaultButton="Button1"
$MessageBoxOptions="DefaultDesktopOnly" # force the message to ON TOP of all open windows....
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
$msgBoxInput= [System.Windows.Forms.MessageBox]::Show($text, $title, $MessageBoxButtons, $MessageBoxIcon, $MessageBoxDefaultButton, $MessageBoxOptions)

}

function RebootComputer
{$time = 60
$server = "."
$comment = "We need to restart the computer for the Windows 10 Required Upgrade, please save your work and close any open documents, the computer will restart in $time seconds, after the restart please try the upgrade in Software Center again."
$reboot = @("/r", "/t", $time, "/m", "\\$server", "/c", $comment)
& shutdown $reboot
}

function ExitWithCode
{
    param
    (
        $exitcode
    )

    $host.SetShouldExit($exitcode)
    exit
} 

# This function just gets $true or $false
function Test-RegistryValue($regpath, $regkey)
{
    $key = Get-Item -LiteralPath $regpath -ErrorAction SilentlyContinue
    logwrite "checking for the following regpath: $key"
    $key -and $null -ne $key.GetValue($regkey, $null)
}

# set's a registry key
function Set-RegistryValue($regpath, $regkey, $regvalue)
{logwrite "About the write the following: $regpath $regkey $regvalue" 
New-ItemProperty -Path $regpath -Name $regkey -Value $regvalue -PropertyType String -Force| Out-Null}

function read-reg ($regpath, $regkey)
{(Get-ItemProperty -Path $regpath -Name $regkey).$regkey}

 # if no deferrals left, start the task sequence
 function CheckDeferralsLeft(){

$regpath2 = "HKCU:\Software\$CompanyName"
$regkey2 = "NumberOfUpgradeDefers"
 LogWrite "Checking if NumberOfUpgradeDefers has any deferrals left..."
 $val2 = read-reg $regpath2 $regkey2
if ($val2 -eq "0")
    {
    LogWrite "NumberOfUpgradeDefers=0, starting task sequence..."
    StartTaskSequence}
else
    {LogWrite "NumberOfUpgradeDefers = $val2 will exit code 99..."
    ExitWithCode "99"
    }
}

# check for the Do_Not_Upgrade.txt file
function CheckFor_Do_Not_Upgrade($path){

if(![System.IO.File]::Exists($path)){
    # file with path $path doesn't exist
    LogWrite "File $path doesn't exist, continuing..."
    }
    else
    {LogWrite "File $path exists, exit(99)"
    ExitWithCode "99"}
}

# this function basically runs all the pre-checks prior to starting the task sequence, if you got here then the task sequence is destined to run
function StartTaskSequence
{
LogWrite "Starting: final pre-checks before starting the task sequence..."

# create upgrade_forced.txt file, this is so that the task sequence knows that the HTA had no deferrals left or ran out of time or was accepted by the user to upgrade.
LogWrite "Starting: creating 'C:\ProgramData\Upgrade_Forced.txt' so that the task sequence can run"
New-Item "C:\ProgramData\Upgrade_Forced.txt" -ItemType file -ErrorAction SilentlyContinue

# check is model supported
LogWrite "Starting: Check if MODEL is supported..."
$ThisModel = Get-CimInstance -ClassName Win32_ComputerSystem | select Model
$SupportedModels = @(
"3236%",
"3237%",
"3227%",
"3228%",
"3218%",
"0606%",
"4223%",
"10A8%",
"10AA%",
"10A6%",
"4351%",
"4353%",
"3220%",
"20B7%",
"20AM%",
"20A8%",
"20BH%",
"20cg%",
"20ch%",
"20AL%",
"20CL%",
"20EG%",
"20GG%",
"20GH%",
"20BU%",
"30a6%",
"30a8%",
"20BS%",
"20BT%",
"%20FE%",
"20EQ%",
"20FM%",
"20FN%",
"20F5%",
"10FL%",
"10FG%",
"10FC%",
"%10FG%",
"30A6%",
"30A8%",
"30B5%",
"30B7%",
"%VMware%",
"Virtual Machine%",
"Parallels Virtual Platform%",
"%Surface Pro 4%",
"%Surface Book%",
"HP EliteBook 820 G3%",
"HP EliteBook 820 G4%",
"HP EliteBook 840 G3%",
"HP EliteBook 840 G4%",
"HP EliteBook x360%",
"HP EliteBook 830 G5%",
"HP EliteBook 850 G5%",
"HP Z440 Workstation%",
"HP Zbook 15 G3%",
"HP ZBook 15 G4%",
"HP EliteDesk 800 G3 DM 35W%",
"HP EliteDesk 800 G3 TWR%",
"HP EliteDesk 800 G3 SFF%",
"HP EliteDesk 800 G3 Mini 35W%", 
"HP EliteDesk 800 G4 DM 35W%",
"HP EliteDesk 800 G4 TWR%",
"HP EliteDesk 800 G4 SFF%",
"HP ProBook 650 G2%",
"HP Z240%",
"HP Z840 Workstation%",
"HP Elite x2 1012 G2%",
"HP Elite x2 1013 G3%",
"HP Elite x360 1030 G2%",
"HP Probook 650 G3%",
"HP Probook 650 G4%",
"HP Z6 G4 Workstation%",
"HP Zbook 15 G5%",
"%Surface Go%"
)
foreach ($Model in $SupportedModels){
    If (Get-WmiObject -Class:Win32_ComputerSystem -Filter:"(Model LIKE '$Model')" -ComputerName:localhost)
        { Logwrite "$Model is supported, continuing !"
        $Supported=$true
        break }
        Else
        {}
}
If ($Supported) {LogWrite "$ThisModel is supported, can continue..."}
else
{LogWrite "This computer model ($ThisModel) is not supported, popping up message to user"

$a = (Get-WmiObject Win32_Computersystem |  select Manufacturer, Model)
$text="Sorry, but this computer model is NOT supported for the Windows 10 Required Upgrade. Please raise a ticket with GSD showing this message. `n`nThe following computer model is not supported: $a"
ShowMessage ($text)

# not supported, so exit from the wrapper with exit code 99

ExitWithCode "99"}

# check IsLaptop true then check for Power connection, tested on Surface Pro 4 and works.

$computer = “localhost” 
if(Get-WmiObject -Class win32_systemenclosure -ComputerName $computer | Where-Object { $_.chassistypes -eq 8 -or $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 -or $_.chassistypes -eq 11 -or $_.chassistypes -eq 12 -or $_.chassistypes -eq 14 -or $_.chassistypes -eq 31})
    { $isLaptop = $true
    LogWrite "Laptop was detected, will check that Power is plugged in..."
    if ((Get-CimInstance win32_battery).batterystatus -eq "1")
        {LogWrite "Computer is discharging, will popup message to end user to connect Power"
        
        do {
        $text="Please connect Power to continue. `n`nAfter you have connected power, click on OK to continue."
        ShowMessage ($text)
            }
        while ((Get-CimInstance win32_battery).batterystatus -eq "1")
        
        }
       else
        {LogWrite "Computer is connected to Power..."}}
else
    {LogWrite "Laptop was NOT detected"}

#check for free disc space

do

{$free=(Get-WmiObject Win32_LogicalDisk | where-object {$_.deviceid -eq $env:systemdrive} | select deviceid,freespace, size)
    $freespace=$free.freespace/1gb
    if ($freespace -ge 20)
        {LogWrite "Computer has enough free hard disc space, detected $freespace"
        }
    else
        {LogWrite "Computer does not have enough free hard disc space, detected $freespace, messaging user to free up space to continue..."
            $text="Please free up disc space to continue the Windows 10 Required Upgrade. You must have at least 20GB of free hard disc space on C:\. . `n`nAfter you have freed up some space, click on OK to continue."
            ShowMessage ($text) }
}
while ($freespace -le 20)

# check for Pulse VPN (usually identified with a default gateway = 0.0.0.0)

$NICS=(Get-WmiObject -Class Win32_IP4RouteTable | where { $_.destination -eq '0.0.0.0' -and $_.mask -eq '0.0.0.0'} | select nexthop, metric1, interfaceindex)

if ($NICS.nexthop -eq '0.0.0.0')
    {LogWrite "Pulse VPN was detected, aborting with Exit code 99"
    $text="Pulse VPN detected. The Windows 10 Required Upgrade cannot continue while connected to $CompanyName via the Pulse VPN, please retry the upgrade from Software Center the next time you are in the office. `n`nPress OK to exit the upgrade."
    ShowMessage ($text)
    ExitWithCode "99"}
else
    {LogWrite "Pulse VPN not detected, continuing..."}

# check for pending reboot
LogWrite "checking for a pending reboot..."

if (Test-PendingReboot){
LogWrite "RebootPending is  true, , notifying user to click OK to reboot....."
$text="WARNING: We are trying to upgrade your computer to the latest version of Windows 10. However there is a pending restart. Please click OK to restart the computer. `n`nNote: After the restart, please LOGON again to continue this process using Software Center."
ShowMessage ($text)
RebootComputer
ExitWithCode "99" }

else
{
LogWrite "RebootPending is NOT true."
}

# clean out registry settings for the next upgrade attempt.
LogWrite "Starting: remove the UpgradeComputer reg keys so that the next upgrade cycle can start fresh."

$regpath = "HKCU:\Software\$CompanyName\"
$regkey = "UpgradeComputer"
DeleteRegKey $regpath $regkey

$regpath = "HKCU:\Software\$CompanyName\"
$regkey = "NumberOfUpgradeDefers"
DeleteRegKey $regpath $regkey

$regpath = "HKCU:\Software\$CompanyName\"
$regkey = "Timer"
DeleteRegKey $regpath $regkey


LogWrite "Starting: Exiting wrapper with exit code 0 and about to start the task sequence now."
ExitWithCode "0"}



<#
#
# ----------------------------script starts below this comment------------------------------------------
#
#>

LogWrite "Starting the [Wrapper] script... "


<#
# Step #1, look for C:\ProgramData\DO_NOT_UPGRADE.txt
#>
$path = "C:\ProgramData\DO_NOT_UPGRADE.txt"
LogWrite "Starting: Step #1 Checking if we are allowed to UPGRADE, checking if $path exists.."
CheckFor_Do_Not_Upgrade $path

<#
# Step #2, look for OSBuildNumber abort with exit code 99 if not Windows 10 (approved builds) or Windows 7
#>

$OperatingSystem = (gwmi win32_operatingsystem).caption
LogWrite "Starting: Step #2 for running OS build number and compare it to the Target Build ($TargetBuild), if greater than or equal to targetbuild exit(99)"

# If Win7 then ok to continue...
If ($OperatingSystem -eq "Microsoft Windows 7 Enterprise ")
    {LogWrite "Windows 7 was found, continuing...'"}
else {
        If ($OperatingSystem -eq "Microsoft Windows 10 Enterprise")
            {LogWrite "Windows 10 was found, let's check the build."
            $DetectedBuild = (Get-CimInstance -ClassName Win32_OperatingSystem -Namespace root/cimv2).BuildNumber

                if($DetectedBuild -lt ($TargetBuild)){

                    LogWrite "The Detected build ($DetectedBuild) is less than the Target Build ($TargetBuild), continuing"
                    }
                    else
                    {LogWrite "The Detected build ($DetectedBuild) is greater than or equal to the Target Build ($TargetBuild), will therefore NOT upgrade, exit(99)..."
                    ExitWithCode "99"
                    }   
              }

else
    {
    LogWrite "This is not an approved operating system for the Windows 10 Ugprade, exiting with code 99, detected: '$OperatingSystem'"
    ExitWithCode "99"
    }
}


<#
# Step #3, check if we are allowed to show the HTA, by checking if Upgrade_Forced exists, if so we do NOT WANT to display the HTA, run the task sequence instead (exit (0))
#>

$path = "C:\ProgramData\Upgrade_Forced.txt"
LogWrite "Starting: Step #3 if allowed to show the HTA, if $path exists then start the task sequence."

if(![System.IO.File]::Exists($path)){
    # file with path $path doesn't exist
    LogWrite "File $path doesn't exist, continuing..."
    }
    else
    {LogWrite "File $path exists, therefore we will NOT display the HTA to the end user as they've already run out of defers or time or selected to upgrade!..."
    StartTaskSequence}

<#
# Step #4, check for numberofupgradedefers, Starting check for NumberOfUpgradeDefers in hkcu and if it exists subtract 1)
#>

$regpath = "HKCU:\Software\$CompanyName"
$regkey = "NumberOfUpgradeDefers"
$regexists = $null
LogWrite "Starting: Step #4 Starting check for $regpath in HKCU and if it exists subtract 1"

# Test if the reg key exists (returns $true or $false)
$regexists = Test-RegistryValue $regpath $regkey
LogWrite "Does the '$regpath\$regkey' reg key exist ? $regexists"

# if it exists, get the value
if ($regexists)
    {logwrite "$regkey reg key exists."
    
    $val = read-reg $regpath $regkey
    
    # if the value exists, do things with it
    if ($val)
        {logwrite "The key exists, let's manipulate it"
        if ($val -eq 0)
                {# don't subtract if already at 0
                logwrite "doing nothing, $regpath\$regkey already 0"}
             else
                {$regvalue = ($val -=1)
                logwrite "Subtracting 1 from reg key, poking $regvalue in $regpath\$regkey" 
                Set-RegistryValue $regpath $regkey $regvalue
                }
        }
        else
        {logwrite "WARNING: The key value does not exist"}
        }
else
    {logwrite "WARNING: $regkey reg key does not exist yet."}

<#
# Step #5, remove the UpgradeComputer reg key if it exists, we do this because if it's not present and the HTA is closed via task manager we can catch the missing key and fail with exit code 99 (for example killing MSHTA with task manager).
#>

LogWrite "Starting: Step #5 remove the UpgradeComputer reg key if it exists"
$regpath = "HKCU:\Software\$CompanyName\"
$regkey = "UpgradeComputer"
DeleteRegKey $regpath $regkey

<#
# Step #6, Checking for ScriptDir and Upgrade.hta, DesiredFile = sScriptDir + "upgrade.hta")
#>

$ScriptDir = $env:temp
$UpgradeFile = "upgrade.hta"

LogWrite "Starting: Step #6 Checking for ScriptDir and $UpgradeFile, DesiredFile = $ScriptDir + $UpgradeFile"
$DesiredFile = $ScriptDir + "\" + $UpgradeFile
LogWrite "$DesiredFile"


<#
# Step #7, running MSHTA)
#>


LogWrite "Starting: Step #7 Running MSHTA.EXE"
$FileExe = "C:\Windows\Syswow64\mshta.exe "
LogWrite "Launching MSHTA.EXE with $DesiredFile"


& $FileExe $DesiredFile

# get MSHTA.exe process and wait till it's closed
$target = "mshta"
$process = Get-Process | Where-Object {$_.ProcessName -eq $target}

do
{  # Place action on process start here
    LogWrite "Waiting for the MSHTA.EXE process to close..."
    $process.WaitForExit()
    start-sleep -s 2
    $process = Get-Process | Where-Object {$_.ProcessName -eq $target}
    # The process is now closed
     LogWrite "The MSHTA.EXE process is closed"
    break
}
while ($true)

<#
# Step #8, Running tasks after HTA closed... do some final checks to see if upgrade is allowed, "HKEY_CURRENT_USER\SOFTWARE\$CompanyName\UpgradeComputer","Upgrade_Forced", check for path="C:\ProgramData\DO_NOT_UPGRADE.txt">
#>

# check for check for path="C:\ProgramData\DO_NOT_UPGRADE.txt", remember this file could have arrived while the popup was on the screen, so we check for it again, also check for ("HKEY_CURRENT_USER\SOFTWARE\$CompanyName\UpgradeComputer","Upgrade_Forced"

$path = "C:\ProgramData\DO_NOT_UPGRADE.txt"
CheckFor_Do_Not_Upgrade $path

$regpath = "HKCU:\Software\$CompanyName"
$regkey = "UpgradeComputer"
$regvalue = "Upgrade_Forced"
LogWrite "Starting: Step #8 Running tasks after HTA closed"

# Test if the reg key exists (returns $true or $false)
$regexists = Test-RegistryValue $regpath $regkey
LogWrite "Does the '$regpath\$regkey' reg key exist ? $regexists"

# if it exists, get the value
if ($regexists)
    {logwrite "$regkey reg key exists."
    
    $val = read-reg $regpath $regkey
    
    # if the value exists, do things with it
    if ($val)
        {logwrite "The key exists, let's manipulate it"
            if ($val -eq "Upgrade_Forced")
                    {logwrite "Upgrade_Forced found, that means it's OK to Upgrade"
                    StartTaskSequence}
            if ($val -eq "Closed_HTA")
                    {
                    logwrite "Closed_HTA found, user closed the HTA, starting final checks including verfying if any deferrals left" 
                   CheckDeferralsLeft
                    }
            if ($val -eq "Defer_Selected")
                    {
                    logwrite "Defer_Selected found, user deferred the HTA, exit with 99" 
                    ExitWithCode "99"
                    }
        }
    else
            {logwrite "WARNING: $regkey reg key does not exist yet."
            CheckDeferralsLeft}
}
else
{logwrite "WARNING: $regkey reg key does not exist yet."
        CheckDeferralsLeft}


<#
# script is complete, let's get out of here...
#>
LogWrite "Exiting the [Wrapper] script." 
StartTaskSequence

