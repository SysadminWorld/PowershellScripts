#Update $RegistryPath Value for your Environment. 
$RegistryPath = "HKLM:\SOFTWARE\Wells Fargo\WaaS"
$RegistryRollBack = "HKLM:\SYSTEM\Setup\Rollback"
$LogFile = "C:\Windows\ccm\Logs\RollbackRecovery.log"
$LastOSUpgradeFrom = Get-ItemPropertyValue -Path "$RegistryPath" -Name LastOSUpgradeFrom
$LastOSUpgradeTo = Get-ItemPropertyValue -Path "$RegistryPath" -Name LastOSUpgradeTo
$RegistryPathFull = "$RegistryPath\$LastOSUpgradeTo"
$WaaSStage = Get-ItemPropertyValue "$RegistryPathFull" 'WaaS_Stage' -ErrorAction SilentlyContinue
$ScriptName = $MyInvocation.MyCommand.Name

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

if ($WaaSStage -eq "Deployment_Started")
    {
    if ((Test-Path "$RegistryRollBack") -eq 'True')
        {     
        if ((Get-ItemPropertyValue -Path $RegistryRollBack -Name "Phase") -ne "5")
            {
            CMTraceLog -Message  "---Starting $ScriptName Script---" -Type 1 -LogFile $LogFile -Component LegalText-OSUninstall
            if ($CurrentBuild -eq $null){$CurrentBuild = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 'ReleaseID' -ErrorAction SilentlyContinue}
            Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticecaption -Value "OS Upgrade to $LastOSUpgradeTo Rolled Back"
            Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticetext -Value "This System has Failed to Upgrade from $LastOSUpgradeFrom to $LastOSUpgradeTo, it will be automatically rescheduled or support staff will reach out to you.  For now, logon and continue with your normal work."
            $CurrentLegalCaption = Get-ItemPropertyValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' -ErrorAction SilentlyContinue
            CMTraceLog -Message  "LegalCaption Data Currently: $CurrentLegalCaption" -Type 1 -LogFile $LogFile -Component LegalText-OSUninstall
            CMTraceLog -Message  "Updated Values: legalnoticecaption & legalnoticetext" -Type 1 -LogFile $LogFile -Component LegalText-OSUninstall
            #Unregister-ScheduledTask -TaskName SetLegalNoticeText-OSUninstall -Confirm:$false
            #CMTraceLog -Message  "Removed Scheduled Task SetLegalNoticeText-OSUninstall" -Type 1 -LogFile $LogFile -Component LegalText-OSUninstall
            CMTraceLog -Message  "---Exiting $ScriptName Script---" -Type 1 -LogFile $LogFile -Component LegalText-OSUninstall
            }
        }
    }