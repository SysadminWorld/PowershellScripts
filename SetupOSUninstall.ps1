#OSUninstall Remediation script, this relies on having several items in place, and assumes you're writing information to the registry during IPU and other task.
#Update $RegistryPath Value for your Environment. 
$RegistryPath = "HKLM:\SOFTWARE\WaaS"
$LogFile = "C:\Windows\ccm\Logs\OSUninstall.log"
$OSUninstallBuild = Get-ItemPropertyValue -Path "$RegistryPath" -Name OSUninstall
$RegistryPathFull = "$RegistryPath\$OSUninstallBuild"

$WaaSStage = Get-ItemPropertyValue "$RegistryPathFull" 'WaaS_Stage' -ErrorAction SilentlyContinue
$IPUPackageID = Get-ItemPropertyValue "$RegistryPathFull" 'IPUPackageID' -ErrorAction SilentlyContinue
$ScriptName = $MyInvocation.MyCommand.Name

function Test-RegistryValue {

param (

 [parameter(Mandatory=$true)]
 [ValidateNotNullOrEmpty()]$Path,

[parameter(Mandatory=$true)]
 [ValidateNotNullOrEmpty()]$Value
)

try {

Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
 return $true
 }

catch {

return $false

}

}


#region: CMTraceLog Function formats logging in CMTrace style
        function CMTraceLog {
         [CmdletBinding()]
    Param (
		    [Parameter(Mandatory=$false)]
		    $Message,
 
		    [Parameter(Mandatory=$false)]
		    $ErrorMessage,
 
		    [Parameter(Mandatory=$false)]
		    $Component = "OSUninstall",
 
		    [Parameter(Mandatory=$false)]
		    [int]$Type,
		
		    [Parameter(Mandatory=$true)]
		    $LogFile
	    )
    <#
    Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
    #>
	    $Time = Get-Date -Format "HH:mm:ss.ffffff"
	    $Date = Get-Date -Format "MM-dd-yyyy"
 
	    if ($ErrorMessage -ne $null) {$Type = 3}
	    if ($Component -eq $null) {$Component = " "}
	    if ($Type -eq $null) {$Type = 1}
 
	    $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
	    $LogMessage | Out-File -Append -Encoding UTF8 -FilePath $LogFile
    }


function Disable-ProvMode
  {
  if ((Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\CCM\CcmExec' 'ProvisioningMode') -eq 'true') 
        {
        $ProvMode = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\CCM\CcmExec' 'ProvisioningMode' -ErrorAction SilentlyContinue
        CMTraceLog -Message  "ProvMode Status: $ProvMode" -Type 3 -LogFile $LogFile
        if ($RunningAsSystem -eq "True"-and $ScriptLogging -eq "True"){CMTraceServerLog -Message  "ProvMode Status: $ProvMode" -Type 3 -ServerLogFile $ServerLogFile}
        CMTraceLog -Message  "Removing Machine From Provisioning Mode and wait 30 seconds" -Type 2 -LogFile $LogFile
        if ($RunningAsSystem -eq "True"-and $ScriptLogging -eq "True"){CMTraceServerLog -Message  "Removing Machine From Provisioning Mode and wait 30 seconds" -Type 2 -ServerLogFile $ServerLogFile}   
        Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name SetClientProvisioningMode -ArgumentList $false
        Start-Sleep -Seconds 30
        $ProvMode = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\CCM\CcmExec' 'ProvisioningMode' -ErrorAction SilentlyContinue
        if ($provmode -eq "True") 
            {
            CMTraceLog -Message  "ProvMode Status: $ProvMode" -Type 3 -LogFile $LogFile
            if ($RunningAsSystem -eq "True"-and $ScriptLogging -eq "True"){CMTraceServerLog -Message  "ProvMode Status: $ProvMode" -Type 3 -ServerLogFile $ServerLogFile}
            CMTraceLog -Message  "Removing Machine From Provisioning Mode" -Type 2 -LogFile $LogFile
            if ($RunningAsSystem -eq "True"-and $ScriptLogging -eq "True"){CMTraceServerLog -Message  "Removing Machine From Provisioning Mode" -Type 2 -ServerLogFile $ServerLogFile}   
            Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name SetClientProvisioningMode -ArgumentList $false
            }   
        Else 
            {
            $ProvMode = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\CCM\CcmExec' 'ProvisioningMode' -ErrorAction SilentlyContinue
            CMTraceLog -Message  "ProvMode Status: $ProvMode" -Type 1 -LogFile $LogFile
            if ($RunningAsSystem -eq "True"-and $ScriptLogging -eq "True"){CMTraceServerLog -Message  "ProvMode Status: $ProvMode" -Type 1 -ServerLogFile $ServerLogFile}   
            }

        }
  Else 
        {
        $ProvMode = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\CCM\CcmExec' 'ProvisioningMode' -ErrorAction SilentlyContinue
        Write-Host "ProvMode Status: $ProvMode" -ForegroundColor Green
        CMTraceLog -Message  "ProvMode Status: $ProvMode" -Type 1 -LogFile $LogFile
        if ($RunningAsSystem -eq "True"-and $ScriptLogging -eq "True"){CMTraceServerLog -Message  "ProvMode Status: $ProvMode" -Type 1 -ServerLogFile $ServerLogFile}   
        }
  }


#Create Function to Reset TS if running
 function Reset-TaskSequence
    {
        Write-host "Starting Resetting CM Services to clear out TS" -ForegroundColor Yellow
        CMTraceLog -Message  "Starting Resetting CM Services to clear out TS - Takes about 3 minutes" -Type 2 -LogFile $LogFile
        #if ($RunningAsSystem -eq "True"-and $ScriptLogging -eq "True"){CMTraceServerLog -Message  "Resetting CM Services to clear out TS" -Type 2 -ServerLogFile $ServerLogFile}   
        Set-Service smstsmgr -StartupType manual
        Start-Service smstsmgr
        CMTraceLog -Message  "Stopping the CCMExec & TSManager Services (10 Seconds)" -Type 1 -LogFile $LogFile
        if ((Get-Process CcmExec -ea SilentlyContinue) -ne $Null) {Get-Process CcmExec | Stop-Process -Force}
        #stop-service ccmexec
        if ((Get-Process TSManager -ea SilentlyContinue) -ne $Null) {Get-Process TSManager| Stop-Process -Force}
        #Stop-Service smstsmgr
        Start-Sleep -Seconds 5
        CMTraceLog -Message  "Starting the CCMExec & TSManager Services (30 Seconds)" -Type 1 -LogFile $LogFile
        Start-Service ccmexec
        Start-Sleep -Seconds 5
        Start-Service smstsmgr
        Start-Sleep -Seconds 20
        CMTraceLog -Message  "Stopping the CCMExec & TSManager Services (40 Seconds)" -Type 1 -LogFile $LogFile
        if ((Get-Process TSManager -ea SilentlyContinue) -ne $Null) {Get-Process TSManager| Stop-Process -Force}
        Start-Sleep -Seconds 20
        if ((Get-Process CcmExec -ea SilentlyContinue) -ne $Null) {Get-Process CcmExec | Stop-Process -Force}
        Start-Sleep -Seconds 15
        CMTraceLog -Message  "Starting the CCMExec Service (60 Seconds)" -Type 1 -LogFile $LogFile
        Start-Service ccmexec
        start-sleep -Seconds 60
        CMTraceLog -Message  "Triggering Machine Policy Updates" -Type 1 -LogFile $LogFile
        Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}"
        Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000022}"

        #This looks for the Windows 10 Upgrade Procesa and Stops it, making sure it doesn't accidentally upgrade in an uncontrolled fassion.        
        if ((Get-Process "SetupHost" -ea SilentlyContinue) -eq $null){$SetupRunning = "False"}
        Else 
            {
            $SetupRunning = "True"
            write-host "Setup Running - Stopping Now" -ForegroundColor Yellow
            CMTraceLog -Message  "Setup Running - Stopping Now" -Type 2 -LogFile $LogFile
            #if ($RunningAsSystem -eq "True"-and $ScriptLogging -eq "True"){CMTraceServerLog -Message  "Setup Running - Stopping Now" -Type 2 -ServerLogFile $ServerLogFile}   
            Get-Process "SetupHost"| Stop-Process -Force
            start-sleep -Seconds 30
            if ((Get-Process "SetupHost" -ea SilentlyContinue) -eq $null)
                {$SetupRunning = "False"}
                Else 
                            {$SetupRunning = "True"
                write-host "Setup Running - Stopping Now" -ForegroundColor Yellow
                CMTraceLog -Message  "Setup Running - Stopping Now" -Type 2 -LogFile $LogFile
                #if ($RunningAsSystem -eq "True"-and $ScriptLogging -eq "True"){CMTraceServerLog -Message  "Setup Running - Stopping Now" -Type 2 -ServerLogFile $ServerLogFile}   
                Get-Process "SetupHost"| Stop-Process -Force                    
                }
            }    
        CMTraceLog -Message  "Finished Resetting CM Services to clear out TS" -Type 2 -LogFile $LogFile
        }

    
CMTraceLog -Message  "---Starting $ScriptName---" -Type 1 -LogFile $LogFile

if ((Test-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Value "ReleaseId") -eq "True"){$CurrentBuild = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 'ReleaseId' -ErrorAction SilentlyContinue}
if ($CurrentBuild -eq $null){$CurrentBuild = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 'CurrentBuild' -ErrorAction SilentlyContinue}

#Check for SetupRollback Key & Insure OS is Rolled back version
#0 = Script Not Run, it will then run and update key to 1, along with do some corrective tasks, also sets Legal Notice to Rollback
#1 = Script ran once, it now runs again to completely reset back to WF Defaults
#2 = Script exits after removing the scheduled task and reseting the TS.

if ($WaaSStage -eq "OSUninstallStarted")
    {
    if ((Test-Path "$RegistryPath") -eq 'True')
        {
        $OSUninstallRanKey = Get-Item  -literalpath "$RegistryPath"
        if (($OSUninstallRanKey.GetValue("OSUninstallRan")) -ne $null) 
            {
            if ((Get-ItemPropertyValue -Path "$RegistryPath" -Name "OSUninstallRan") -eq "0")
                {
                #IF you use GPO to force a Lock Screen, update this next line
                #Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Value "C:\windows\Web\Screen\img100.jpg" -Force
                #IF you need to delete the Key use this:
                Remove-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Force
                CMTraceLog -Message  "Cleanup Registry, Old PreFlight & IPU Keys" -Type 1 -LogFile $LogFile
                Remove-ItemProperty -Path $RegistryPathFull -Name IPU* -Force
                Set-ItemProperty -Path $RegistryPathFull -Name "IPUPackageID" -Value $IPUPackageID
                emove-ItemProperty -Path $RegistryPathFull -Name PreFlight* -Force
                Stop-Process -Name winlogon -Force -Verbose
                CMTraceLog -Message  "Set LockScreen to Default" -Type 1 -LogFile $LogFile            
                CMTraceLog -Message  "Starting CCM Disable ProvMode" -Type 1 -LogFile $LogFile
                Disable-ProvMode
                CMTraceLog -Message  "Starting CCM Service & CCMEval" -Type 1 -LogFile $LogFile
                Start-Process "C:\Windows\ccm\CcmEval.exe"
                CMTraceLog -Message  "Triggered CcmEval.exe" -Type 1 -LogFile $LogFile
                Set-ItemProperty -Path "$RegistryPath" -Name "OSUninstallRan" -Value "1"
                }
           if ((Get-ItemPropertyValue -Path "$RegistryPath" -Name "OSUninstallRan") -eq "1")      
                {
                CMTraceLog -Message  "Waiting 5 Minutes for CMClient to become active" -Type 1 -LogFile $LogFile
                Start-Sleep -Seconds 60
                CMTraceLog -Message  "Waiting 4 Minutes for CMClient to become active" -Type 1 -LogFile $LogFile
                Start-Sleep -Seconds 60
                CMTraceLog -Message  "Waiting 3 Minutes for CMClient to become active" -Type 1 -LogFile $LogFile
                Start-Sleep -Seconds 60
                CMTraceLog -Message  "Waiting 2 Minutes for CMClient to become active" -Type 1 -LogFile $LogFile
                Start-Sleep -Seconds 60
                CMTraceLog -Message  "Waiting 1 Minutes for CMClient to become active" -Type 1 -LogFile $LogFile
                Start-Sleep -Seconds 60
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name "LockScreenImage" -Value "C:\windows\Web\Screen\img100.jpg" -Force
                Disable-ProvMode
                Unregister-ScheduledTask -TaskName ForceCcmExecProvModeFixRunNow2Hours -Confirm:$false
                Unregister-ScheduledTask -TaskName ForceLockScreenCleanup2Hours -Confirm:$false
                Unregister-ScheduledTask -TaskName LockScreenCleanUp -Confirm:$false
                CMTraceLog -Message  "Removed LockScreen Cleanup Scheduled Tasks" -Type 1 -LogFile $LogFile
                Reset-TaskSequence
                CMTraceLog -Message  "Reset IPU TS Execution History for $IPUPackageID " -Type 1 -LogFile $LogFile
                Remove-Item "HKLM:\SOFTWARE\Microsoft\SMS\Mobile Client\Software Distribution\Execution History\System\$IPUPackageID" -Recurse -Force
                Set-ItemProperty -Path $RegistryPathFull -Name "WaaS_Stage" -Value "OSUninstallComplete"
                CMTraceLog -Message  "Triggering Hardware Inventory" -Type 1 -LogFile $LogFile
                Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule “{00000000-0000-0000-0000-000000000001}”
                Unregister-ScheduledTask -TaskName SetupOSUninstall -Confirm:$false
                Remove-ItemProperty -Path "$RegistryPath" -Name "OSUninstallRan"
                Remove-ItemProperty -Path $RegistryPathFull -Name IPU* -Force
                CMTraceLog -Message  "Removed OSUninstallRan Reg Value" -Type 1 -LogFile $LogFile
                CMTraceLog -Message  "Removed OSUninstall Scheduled Tasks" -Type 1 -LogFile $LogFile
                Start-ScheduledTask -TaskName OSUninstallCleanUp
                CMTraceLog -Message  "Triggering OSUninstallCleanUp Scheduled Task" -Type 1 -LogFile $LogFile
                CMTraceLog -Message  "---Exiting $ScriptName---" -Type 1 -LogFile $LogFile
                Start-Process "C:\Windows\ccm\CcmEval.exe"
                Exit
                }

            }
        }
    }

