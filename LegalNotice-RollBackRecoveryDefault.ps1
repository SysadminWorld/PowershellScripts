#Update $RegistryPath Value for your Environment. 
$RegistryPath = "HKLM:\SOFTWARE\WaaS"
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

if ($WaaSStage -eq "Deployment_RollBack") #OSUninstall is set using a OSUninstall TS post Upgrade, to allow being reverted, so this will never run if this key isn't set by the OSUninstall TS
    {
    CMTraceLog -Message  "---Starting $ScriptName Script---" -Type 1 -LogFile $LogFile -Component LegalText-Default
    $CurrentLegalCaption = Get-ItemPropertyValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' -ErrorAction SilentlyContinue
    CMTraceLog -Message  "LegalCaption Data Currently: $CurrentLegalCaption" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticecaption -Value "Welcome"
    Set-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Name legalnoticetext -Value "Welcome to GARYTOWN.COM, home of @GWBLOK and WaaS Information."
    CMTraceLog -Message  "Updated Values: legalnoticecaption & legalnoticetext" -Type 1 -LogFile $LogFile -Component LegalText-Default
    $CurrentLegalCaption = Get-ItemPropertyValue 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' 'legalnoticecaption' -ErrorAction SilentlyContinue
    CMTraceLog -Message  "LegalCaption Data Currently: $CurrentLegalCaption" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-OSUninstall -Confirm:$false
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-OSUninstallDefault -Confirm:$false
    Unregister-ScheduledTask -TaskName SetupOSUninstall -Confirm:$false
    Unregister-ScheduledTask -TaskName OSUninstallCleanup -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Tasks for OSUninstall" -Type 1 -LogFile $LogFile -Component LegalText-Default
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-RollBackRecovery -Confirm:$false
    Unregister-ScheduledTask -TaskName SetLegalNoticeText-RollBackRecoveryDefault -Confirm:$false
    Unregister-ScheduledTask -TaskName RollBackRecovery -Confirm:$false
    CMTraceLog -Message  "Removed Scheduled Tasks for RollBackRecovery" -Type 1 -LogFile $LogFile -Component LegalText-Default

    CMTraceLog -Message  "---Exiting $ScriptName Script---" -Type 1 -LogFile $LogFile -Component LegalText-Default
    }