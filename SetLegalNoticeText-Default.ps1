#Sets the Legal Text back to the Environment Defaults after IPU Complete.  Logs to SMSTS_PostActions.log

#Update $RegistryPath Value for your Environment. 
$LogFile = "C:\Windows\ccm\Logs\SMSTS_PostActions.log"
$RegistryPath = "HKLM:SOFTWARE\WaaS"
$CurrentBuild = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 'ReleaseId' -ErrorAction SilentlyContinue


function Test-RegistryValue
{
    <# 
    .SYNOPSIS 
    Tests if a registry value exists. 
     
    .DESCRIPTION 
    The usual ways for checking if a registry value exists don't handle when a value simply has an empty or null value. This function actually checks if a key has a value with a given name. 
     
    .EXAMPLE 
    Test-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title' 
     
    Returns `True` if `hklm:\Software\Carbon\Test` contains a value named 'Title'. `False` otherwise. 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set. Will be created if it doesn't exist.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    #Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        return $false
    }
    
    $properties = Get-ItemProperty -Path $Path 
    if( -not $properties )
    {
        return $false
    }
    
    $member = Get-Member -InputObject $properties -Name $Name
    if( $member )
    {
        return $true
    }
    else
    {
        return $false
    }
}

if ((Test-RegistryValue -Path "$RegistryPath" -Name "OSUninstall") -eq $true)
    {
    $OSUninstallBuild = Get-ItemPropertyValue -Path "$RegistryPath" -Name "OSUninstall"
    $RegistryPathFull = "$RegistryPath\$OSUninstallBuild"
    }
Else
    {
    $RegistryPathFull = "$RegistryPath\$CurrentBuild"
    }
$WaaSStage = Get-ItemPropertyValue "$RegistryPathFull" 'WaaS_Stage' -ErrorAction SilentlyContinue


#region: CMTraceLog Function formats logging in CMTrace style
        function CMTraceLog {
         [CmdletBinding()]
    Param (
		    [Parameter(Mandatory=$false)]
		    $Message,
 
		    [Parameter(Mandatory=$false)]
		    $ErrorMessage,
 
		    [Parameter(Mandatory=$false)]
		    $Component = $env:computername,
 
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

if ($WaaSStage -eq "Deployment_Success" -or $WaaSStage -eq "IPU_Success")
    {
    CMTraceLog -Message  "---Starting LegalNotice-Default Script---" -Type 1 -LogFile $LogFile -Component LegalText-Default
    CMTraceLog -Message  "Waiting 2 Minutes for other processes to complete.. what process?  I don't know, just other ones" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Start-Sleep -Seconds 120
    $CurrentLegalCaption = Get-ItemPropertyValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' -ErrorAction SilentlyContinue
    CMTraceLog -Message  "LegalCaption Data Currently: $CurrentLegalCaption" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticecaption -Value "Welcome"
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticetext -Value "You're entering GARYTOWN, remember, what happens in GARYTOWN, gets blogged and tweeted."
    $CurrentLegalCaption = Get-ItemPropertyValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' -ErrorAction SilentlyContinue
    CMTraceLog -Message  "LegalCaption Data Currently: $CurrentLegalCaption" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-OSUpgradeComplete -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Task SetLegalNoticeText-OSUpgradeComplete" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-Default -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Task SetLegalNoticeText-Default" -Type 1 -LogFile $LogFile -Component LegalText-Default
    CMTraceLog -Message  "---Exiting LegalNotice-Default Script---" -Type 1 -LogFile $LogFile -Component LegalText-Default
    }

    #Added this to be able to use the Same Script for both Upgrades & OSUnisntall.  Had issues with timing and would delete before it ran.
    #This only Runs 1/2 of the items, referting back to default, but not removing the tasks, I don't want it to do cleanup until I know the OSUninstall Scripts are complete
    if ($WaaSStage -eq "OSUninstallStarted") #OSUninstall is set using a OSUninstall TS post Upgrade, to allow being reverted, so this will never run if this key isn't set by the OSUninstall TS
    {
    $LogFile = "C:\Windows\ccm\Logs\OSUninstall.log"
    CMTraceLog -Message  "---Starting LegalNotice-Default Script---" -Type 1 -LogFile $LogFile -Component LegalText-Default
    $CurrentLegalCaption = Get-ItemPropertyValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' -ErrorAction SilentlyContinue
    CMTraceLog -Message  "LegalCaption Data Currently: $CurrentLegalCaption" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticecaption -Value "Welcome"
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticetext -Value "You're entering GARYTOWN, remember, what happens in GARYTOWN, gets blogged and tweeted."
    CMTraceLog -Message  "Updated Values: legalnoticecaption & legalnoticetext" -Type 1 -LogFile $LogFile -Component LegalText-Default
    $CurrentLegalCaption = Get-ItemPropertyValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' -ErrorAction SilentlyContinue
    CMTraceLog -Message  "LegalCaption Data Currently: $CurrentLegalCaption" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-OSUninstall -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Task SetLegalNoticeText-OSUninstall" -Type 1 -LogFile $LogFile -Component LegalText-Default
    CMTraceLog -Message  "---Exiting LegalNotice-Default Script---" -Type 1 -LogFile $LogFile -Component LegalText-Default
    }

    #This runs when the OSUninstall is complete, it will now cleanup after itself, removing scripts and scheduled tasks.
    if ($WaaSStage -eq "OSUninstallComplete") #OSUninstall is set using a OSUninstall TS post Upgrade, to allow being reverted, so this will never run if this key isn't set by the OSUninstall TS
    {
    $LogFile = "C:\Windows\ccm\Logs\OSUninstall.log"
    CMTraceLog -Message  "---Starting LegalNotice-Default Script---" -Type 1 -LogFile $LogFile -Component LegalText-Default
    $CurrentLegalCaption = Get-ItemPropertyValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' -ErrorAction SilentlyContinue
    CMTraceLog -Message  "LegalCaption Data Currently: $CurrentLegalCaption" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticecaption -Value "Welcome"
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticetext -Value "You're entering GARYTOWN, remember, what happens in GARYTOWN, gets blogged and tweeted."
    CMTraceLog -Message  "Updated Values: legalnoticecaption & legalnoticetext" -Type 1 -LogFile $LogFile -Component LegalText-Default
    $CurrentLegalCaption = Get-ItemPropertyValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' -ErrorAction SilentlyContinue
    CMTraceLog -Message  "LegalCaption Data Currently: $CurrentLegalCaption" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-OSUpgradeComplete -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Task SetLegalNoticeText-OSUpgradeComplete" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-OSUninstallSuccessful -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Task SetLegalNoticeText-OSUninstallSuccessful" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-Default -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Task SetLegalNoticeText-Default" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-OSUninstall -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Task SetLegalNoticeText-OSUninstall" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-OSUninstallDefault -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Task SetLegalNoticeText-OSUninstallDefault" -Type 1 -LogFile $LogFile -Component LegalText-Default
    CMTraceLog -Message  "Triggering Scheduled OSUninstallCleanUp" -Type 1 -LogFile $LogFile -Component LegalText-Default
    CMTraceLog -Message  "---Exiting LegalNotice-Default Script---" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Start-ScheduledTask -TaskName "OSUninstallCleanUp"
    }