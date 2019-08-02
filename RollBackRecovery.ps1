<#
RollBack (Failed Upgrade) Remediation script, this is triggered by a scheduled task that you should set to run daily / start up.
It will check to see if a rollback has happened and then do the required actions to fix the CM Client.

#>
#Update $RegistryPath Value for your Environment. 
$RegistryPath = "HKLM:\SOFTWARE\WaaS"
$RegistryRollBack = "HKLM:\SYSTEM\Setup\Rollback"
$RegistryTemp = "HKLM:\SOFTWARE\RollBack"
$LogFile = "C:\Windows\ccm\Logs\RollBackRecovery.log"
$LastOSUpgradeFrom = Get-ItemPropertyValue -Path "$RegistryPath" -Name LastOSUpgradeFrom -ErrorAction SilentlyContinue
$LastOSUpgradeTo = Get-ItemPropertyValue -Path "$RegistryPath" -Name LastOSUpgradeTo -ErrorAction SilentlyContinue
$RegistryPathFull = "$RegistryPath\$LastOSUpgradeTo"
$WaaSStage = Get-ItemPropertyValue "$RegistryPathFull" 'WaaS_Stage' -ErrorAction SilentlyContinue
$ScriptName = $MyInvocation.MyCommand.Name


    [string[]] $Path = @(

        "$env:Systemdrive\`$WINDOWS.~BT\Sources\Panther"
        "$env:Systemdrive\`$WINDOWS.~BT\Sources\Rollback"
        "$env:SystemRoot\Panther"
        "$env:SystemRoot\SysWOW64\PKG_LOGS"
        "$env:SystemRoot\CCM\Logs"
        )


    [string] $TargetRoot = '\\src\Logs$'
    [string] $LogID = "IPU\$LastOSUpgradeTo\$env:ComputerName"
    [string[]] $Exclude = @( '*.exe','*.wim','*.dll','*.ttf','*.mui' )
    [switch] $recurse
    [switch] $SkipZip






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
		    $Component = "RollBackRecovery",
 
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
        if ((Get-Process TSServiceUI -ea SilentlyContinue) -ne $Null) {Get-Process TSServiceUI | Stop-Process -Force}
        Start-Sleep -Seconds 20
        if ((Get-Process CcmExec -ea SilentlyContinue) -ne $Null) {Get-Process CcmExec | Stop-Process -Force}
        if ((Get-Process TSServiceUI -ea SilentlyContinue) -ne $Null) {Get-Process TSServiceUI | Stop-Process -Force}
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
            if ((Get-Process TSServiceUI -ea SilentlyContinue) -ne $Null) {Get-Process TSServiceUI | Stop-Process -Force}
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


#Check for Rollback Key and run section if Rollback detected


    if (Test-Path "$RegistryRollBack")
        {     
        if ((Get-ItemPropertyValue -Path $RegistryRollBack -Name "Phase") -ne "5")
            {
            if ((Test-Path $Registrytemp) -ne $True)
                {
                CMTraceLog -Message  "---Starting $ScriptName Script---" -Type 1 -LogFile $LogFile
                #Set OSRollBackRan key to 0, to know where in the script it was if a reboot should occur
                New-Item -Path $RegistryTemp –Force
                Set-ItemProperty -Path "$RegistryTemp" -Name "OSRollbackRan" -Value "0" -Force
                #Force the default Windows LockScreen  images to be the actual LockScreen Image.  Update for your envirnment. 
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name LockScreenImage -Value "C:\windows\Web\Screen\img100.jpg" -Force
                Stop-Process -Name winlogon -Force -Verbose
                CMTraceLog -Message  "Starting CCM Disable ProvMode" -Type 1 -LogFile $LogFile
                Disable-ProvMode
                CMTraceLog -Message  "Starting CCM Service & CCMEval" -Type 1 -LogFile $LogFile
                Start-Process "C:\Windows\ccm\CcmEval.exe"
                CMTraceLog -Message  "Triggered CcmEval.exe" -Type 1 -LogFile $LogFile
                #Set OSRollbackRan key to 1, to know where in the script it was if a reboot should occur
                Set-ItemProperty -Path "$RegistryTemp" -Name "OSRollbackRan" -Value "1" -Force
                }
            if ((Get-ItemPropertyValue -Path "$RegistryTemp" -Name "OSRollbackRan") -eq "1")      
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
                Disable-ProvMode
                Reset-TaskSequence
                #Set OSRollbackRan key to 2, to know where in the script it was if a reboot should occur
                Set-ItemProperty -Path "$RegistryTemp" -Name "OSRollbackRan" -Value "2" -Force
                }
            if ((Get-ItemPropertyValue -Path "$RegistryTemp" -Name "OSRollbackRan") -eq "2")      
                {     
                CMTraceLog -Message  "Triggering CM Hardware Inventory" -Type 1 -LogFile $LogFile
                Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000001}"
                CMTraceLog -Message  "Triggering CM Machine Policy Retrieval Cycle" -Type 1 -LogFile $LogFile
                Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}"
                CMTraceLog -Message  "Triggering CM Machine Policy Evaluation Cycle" -Type 1 -LogFile $LogFile
                Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000022}"
                CMTraceLog -Message  "Waiting 1 Minutes for Policy to Update" -Type 1 -LogFile $LogFile
                Start-Sleep -Seconds 60
                CMTraceLog -Message  "Triggering CM Machine Policy Evaluation Cycle" -Type 1 -LogFile $LogFile
                Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000113}"
                #Added Phase of Failure into OSUninstall_TellUsMore, because we don't have any dedicated values for RollBack
                Set-ItemProperty -Path "$RegistryPathFull" -Name "RollBackPhase" -Value "$(Get-ItemPropertyValue -Path $RegistryRollBack -Name "Phase")" -Force
                Set-ItemProperty -Path "$RegistryPathFull" -Name "WaaS_Stage" -Value "Deployment_RollBack" -Force
                #Set OSRollbackRan key to 3, to know where in the script it was if a reboot should occur, 3 basically means every time the script is triggered, it will do nothing, because it's already completed the required steps
                Set-ItemProperty -Path "$RegistryTemp" -Name "OSRollbackRan" -Value "3" -Force
                }
             if ((Get-ItemPropertyValue -Path "$RegistryTemp" -Name "OSRollbackRan") -eq "3")      
                {   
                #Grab Logs and Backup To Server
                CMTraceLog -Message  "Backing Up Logs to Server" -Type 1 -LogFile $LogFile
                CMTraceLog -Message  "Location: $TargetRoot\$LogID" -Type 1 -LogFile $LogFile
                #region Prepare Target

                write-verbose "Log Archive Tool  1.0.<Version>" 

                write-verbose "Create Target $TargetRoot\$LogID"
                new-item -itemtype Directory -Path $TargetRoot\$LogID -force -erroraction SilentlyContinue | out-null 

                $TagFile = "$TargetRoot\$LogID\$($LogID.Replace('\','_'))"

                #endregion

                #region Create temporary Store

                $TempPath = [System.IO.Path]::GetTempFileName()
                remove-item $TempPath
                new-item -type directory -path $TempPath -force | out-null

                foreach ( $Item in $Path ) { 

                    $TmpTarget = (join-path $TempPath ( split-path -NoQualifier $Item ))
                    write-Verbose "COPy $Item to $TmpTarget"
                    copy-item -path $Item -Destination $TmpTarget -Force -Recurse -exclude $Exclude -ErrorAction SilentlyContinue

                }

                Compress-Archive -path "$TempPath\*" -DestinationPath "$TargetRoot\$LogID\$($LogID.Replace('\','_'))-$([datetime]::now.Tostring('s').Replace(':','-')).zip" -Force
                remove-item $tempPath -Recurse -Force

                #endregion
                CMTraceLog -Message  "Finished Backing Up Logs to Server" -Type 1 -LogFile $LogFile
                Set-ItemProperty -Path "$RegistryPathFull" -Name "RollBackLog" -Value "LogLocation: $TargetRoot\$LogID" -Force
                Set-ItemProperty -Path "$RegistryTemp" -Name "OSRollbackRan" -Value "4" -Force
                
                
                CMTraceLog -Message  "---Exiting $ScriptName Script---" -Type 1 -LogFile $LogFile
                
                
                Start-Process "C:\Windows\ccm\CcmEval.exe"
                Exit
                }
            }
        }
    else
        {
        if ((Test-Path "$RegistryTemp") -eq 'True')
            {
            Remove-Item -Path "$RegistryTemp" -Force
            }
        }
        

