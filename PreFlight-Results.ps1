<#
Script used to gather results from Both the Previous Script which triggers a baseline and reports compliance / non-compliance.  Then takes the Soft Blocker info and figures out the correct path to follow.
Creates the Registry Values for the PreFlight Module.
Logs to CM Logs Folder: SMSTS_PreFlight.log

#>

#region: CMTraceLog Function formats logging in CMTrace style
        function CMTraceLog {
         [CmdletBinding()]
    Param (
		    [Parameter(Mandatory=$false)]
		    $Message,
 
		    [Parameter(Mandatory=$false)]
		    $ErrorMessage,
 
		    [Parameter(Mandatory=$false)]
		    $Component = "IPU_PreFlight",
 
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
 

#Function to increment the PreFlightAttemps Key for each run

function Set-RegistryValueIncrement {
    [cmdletbinding()]
    param (
        [string] $path,
        [string] $Name
    )

    try { [int]$Value = Get-ItemPropertyValue @PSBoundParameters -ErrorAction SilentlyContinue } catch {}
    Set-ItemProperty @PSBoundParameters -Value ($Value + 1).ToString() 
}

#Setup TS Environment
try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
}
catch
{
	Write-Verbose "Not running in a task sequence."
}

$LogPath = $tsenv.Value('_SMSTSLogPath')
$LogFile = "$LogPath\SMSTS_PreFlight.log"
$registryPath = "HKLM:\$($tsenv.Value('RegistryPath'))\$($tsenv.Value('SMSTS_BUILD'))"

CMTraceLog -Message  "Starting Pre-Flight Gather Script" -Type 1 -LogFile $LogFile

#Creates or Increments the IPUAttempts Value
CMTraceLog -Message  "Update PreFlight Attempts Regsitry Value" -Type 1 -LogFile $LogFile
Set-RegistryValueIncrement -Path $registryPath -Name PreFlightAttempts


#Creates PreFlight Last Run Value
CMTraceLog -Message  "Create PreFlightLastRun Regsitry Value" -Type 1 -LogFile $LogFile
Set-ItemProperty -Path $registryPath -Name "PreFlightLastRun" -Value (Get-Date -f 's') -Force

#Creates PreFlight Version Value (WaaS Basline Reversion)
CMTraceLog -Message  "Create PreFlightVersion Regsitry Value" -Type 1 -LogFile $LogFile
Set-ItemProperty -Path $registryPath -Name "PreFlightVersion" -Value $tsenv.Value('PreFlight_BaseLineRevision') -Force


$PF_SoftFail = (New-Object -COMObject Microsoft.SMS.TSEnvironment).GetVariables() | Where-Object {$_ -Like "PF_*"}

#IF PreFlight Soft Block Only

if ($PF_SoftFail -ne $null)
    {
    $PFSoftBlock = $True
    if ($tsenv.Value('PF_KillSwitch') -eq "The upgrade has been blocked by an administrator.")
        {
        CMTraceLog -Message  "PreFlight KillSwitch Found" -Type 1 -LogFile $LogFile
        $tsenv.Value("PreFlight_Fails") = "KillSwitch Activated by Administrator"
        $tsenv.Value("PreFlight_UserText") = "Please contact your Line of Business Support with the following information:"
        $tsenv.Value("FailedStepReturnCode") = "254"
        CMTraceLog -Message  "Updatig PreFlight Registry Values: PreFlightCode & PreFlightStatus" -Type 1 -LogFile $LogFile
        Set-ItemProperty -Path $registryPath -Name "PreFlightReturnCode" -Value "KillSwitch" -Force
        Set-ItemProperty -Path $registryPath -Name "PreFlightReturnStatus" -Value "KillSwitch Activated by Administrator" -Force
        }
    Else
        {
        CMTraceLog -Message  "PreFlight Soft Blockers Found" -Type 1 -LogFile $LogFile
        $PF_SoftFail_Results = foreach ($Fails in $PF_SoftFail)
            {
            $tsenv.Value($Fails)
            CMTraceLog -Message  "Soft Pre-Flight Failure: $Fails" -Type 1 -LogFile $LogFile
            }
        #Only Add Soft Failures if no Hard Failures exist
        if (-not($tsenv.Value("PreFlight_NonCompliant")))
            {
            $tsenv.Value("PreFlight_Fails") = $PF_SoftFail_Results | Out-String
            $tsenv.Value("PreFlight_UserText") = "Please Resolve the issue(s) listed below, then click Close"
            $tsenv.Value("FailedStepReturnCode") = "0"
            CMTraceLog -Message  "Updatig PreFlight Registry Values: PreFlightCode & PreFlightStatus" -Type 1 -LogFile $LogFile
            Set-ItemProperty -Path $registryPath -Name "PreFlightReturnCode" -Value "SoftBlocker" -Force
            Set-ItemProperty -Path $registryPath -Name "PreFlightReturnStatus" -Value $tsenv.Value("PreFlight_Fails") -Force
            }
        }
    }

#If PreFlight Hard Block
if ($tsenv.Value("PreFlight_NonCompliant"))
    {
    $PFHardBlock = $True
    CMTraceLog -Message  "Pre-Flight Hard Blockers Found" -Type 1 -LogFile $LogFile
    $tsenv.Value("PreFlight_UserText") = "Please contact your Line of Business Support with the following information:"
    $tsenv.Value("PreFlight_Fails") = $tsenv.Value("PreFlight_NonCompliant")
    $tsenv.Value("FailedStepReturnCode") = "253"
    CMTraceLog -Message  "Updatig PreFlight Registry Values: PreFlightCode & PreFlightStatus" -Type 1 -LogFile $LogFile
    Set-ItemProperty -Path $registryPath -Name "PreFlightReturnCode" -Value "HardBlocker" -Force
    Set-ItemProperty -Path $registryPath -Name "PreFlightReturnStatus" -Value $tsenv.Value("PreFlight_Fails") -Force
    }

if ($PFSoftBlock -ne $True -and $PFHardBlock -ne $True)
    {
    CMTraceLog -Message  "Updatig PreFlight Registry Values: PreFlightCode & PreFlightStatus" -Type 1 -LogFile $LogFile
    CMTraceLog -Message  "No PreFlight Issues Found, continuing onto IPU Process" -Type 1 -LogFile $LogFile
    Set-ItemProperty -Path $registryPath -Name "PreFlightReturnCode" -Value "0" -Force
    Set-ItemProperty -Path $registryPath -Name "PreFlightReturnStatus" -Value "Compliant" -Force
    }
Else
    {
    CMTraceLog -Message  "Setting PreFlight_UserText: $($tsenv.Value('PreFlight_UserText'))" -Type 1 -LogFile $LogFile
    CMTraceLog -Message  "Setting PreFlight_Fails: $($tsenv.Value("PreFlight_Fails"))" -Type 1 -LogFile $LogFile
    CMTraceLog -Message  "Setting FailedStepReturnCode: $($tsenv.Value('FailedStepReturnCode'))" -Type 1 -LogFile $LogFile
    }

CMTraceLog -Message  "Finished Pre-Flight Gather Script" -Type 1 -LogFile $LogFile



