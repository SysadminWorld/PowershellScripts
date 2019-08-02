<#This Script Looks for Baselines with %Pre-Assessment in the name
It then checks when it was last evaluated
IF, the last eval was non-compliant or the last eval is over 24 hours old
  - Then it Triggers Eval and waits for Eval to finish.
Based on Eval, will log Non-Compliant CIs to Task Sequence Variable: PreFlight_NonCompliant
Also logs to SMSTS_PreFlight usign CMTraceLog function.

Second Script "PreFlight-Results" Compiles this data along with the "Soft Blockers" and generates the Error message if nessisary.


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

#Setup TS Environment
try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
}
catch
{
	Write-Verbose "Not running in a task sequence."
}
if ($tsenv)
    {
    $LogPath = $tsenv.Value('_SMSTSLogPath')
    $tsPUI = New-Object -ComObject Microsoft.SMS.TSProgressUI
    }
else
    {
    $LogPath = $env:TEMP
    }   
$LogFile = "$LogPath\SMSTS_PreFlight.log"
$ScriptName = $MyInvocation.MyCommand.Name
    
CMTraceLog -Message  "Starting $ScriptName Script" -Type 1 -LogFile $LogFile

#Trigger WaaS PreAssessment Baseline
$DCM = [WMIClass] "ROOT\ccm\dcm:SMS_DesiredConfiguration"
$WaaSBaseline = Get-WmiObject -Namespace root\ccm\dcm -QUERY "SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName LIKE '%Pre-Assessment'"
$LastEvalTime = $WaaSBaseline.LastEvalTime
$LastEvalString = $LastEvalTime.Substring(0,$LastEvalTime.Length-5)
$LastEvalString = [MATH]::Round($LastEvalString)
$LastEvalString = $LastEvalString.ToString()
$LastEvalString = [DateTime]::ParseExact($LastEvalString,"yyyyMMddHHmmss",$null)
$EvalDifference = New-TimeSpan -Start (Get-Date) -End $LastEvalString
$EvalDifferenceHours = $EvalDifference.Hours

$DCM.TriggerEvaluation($WaaSBaseline.Name, $WaaSBaseline.Version)

#Get Baseline CI's that are Non-Compliant
$DCM = [WMIClass] "ROOT\ccm\dcm:SMS_DesiredConfiguration"
$WaaSBaseline = Get-WmiObject -Namespace root\ccm\dcm -QUERY "SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName LIKE '%Pre-Assessment'"
$UserReport = $DCM.GetUserReport($WaaSBaseline.Name,$WaaSBaseline.Version,$null,0)
[XML]$Details = $UserReport.ComplianceDetails
$WaaSNonCompliant = $Details.ConfigurationItemReport.ReferencedConfigurationItems.ConfigurationItemReport | Where-Object {$_.CIComplianceState -eq "NonCompliant"}




$TimeOut = 1
$TimeOutMax = 300
$Message = "Checking WaaS Baseline Configuration Compliance"
$Step = 1
$MaxStep = 100
#If old Baseline Eval is more than 24 hours old, or if the last eval was NON-COmpliant, then rerun eval and wait for updated results.
if ($EvalDifferenceHours -gt 24 -or $WaaSNonCompliant -ne $null)
    {
    CMTraceLog -Message  "Last Baseline Eval Time: $LastEvalString" -Type 1 -LogFile $LogFile
    if ($EvalDifferenceHours -gt 24){CMTraceLog -Message  "Last Baseline Eval Time older than 24 hours" -Type 1 -LogFile $LogFile}
    if ($WaaSNonCompliant -ne $null){CMTraceLog -Message  "Last Baseline Eval Found non-compliant item, rerunning eval" -Type 1 -LogFile $LogFile}
    do
        {
        If ($TimeOut -gt $TimeOutMax){break}
        $tsPUI.ShowActionProgress(`            $tsenv.Value("_SMSTSOrgName"),`            $tsenv.Value("_SMSTSPackageName"),`            $tsenv.Value("_SMSTSCustomProgressDialogMessage"),`            $tsenv.Value("_SMSTSCurrentActionName"),`            [Convert]::ToUInt32($tsenv.Value("_SMSTSNextInstructionPointer")),`            [Convert]::ToUInt32($tsenv.Value("_SMSTSInstructionTableSize")),`            $Message,`            $Step,`            $MaxStep)
        Start-Sleep -Seconds 1
        $WaaSBaseline.get()
        $UpdatedLastEvalTime = $WaaSBaseline.LastEvalTime
        $TimeOut
        $TimeOut++
        $Step
        $Step++
        #Write-Host "LastEval Time: $LastEvalTime"
        #Write-Host "Updated Time: $UpdatedLastEvalTime"
        }
    until($UpdatedLastEvalTime -ne $LastEvalTime)
    
    $UpdatedLastEvalString = $UpdatedLastEvalTime.Substring(0,$UpdatedLastEvalTime.Length-5)
    $UpdatedLastEvalString = [MATH]::Round($UpdatedLastEvalString)
    $UpdatedLastEvalString = $UpdatedLastEvalString.ToString()
    $UpdatedlastEvalString = [DateTime]::ParseExact($UpdatedLastEvalString,"yyyyMMddHHmmss",$null)
    CMTraceLog -Message  "Updated Baseline Eval Time: $UpdatedlastEvalString" -Type 1 -LogFile $LogFile
    
    #Get Baseline CI's that are Non-Compliant
    $DCM = [WMIClass] "ROOT\ccm\dcm:SMS_DesiredConfiguration"
    $WaaSBaseline = Get-WmiObject -Namespace root\ccm\dcm -QUERY "SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName LIKE '%Pre-Assessment'"
    $UserReport = $DCM.GetUserReport($WaaSBaseline.Name,$WaaSBaseline.Version,$null,0)
    [XML]$Details = $UserReport.ComplianceDetails
    $WaaSNonCompliant = $Details.ConfigurationItemReport.ReferencedConfigurationItems.ConfigurationItemReport | Where-Object {$_.CIComplianceState -eq "NonCompliant"}
    }
Else
    {
    CMTraceLog -Message  "Last Baseline Eval Time: $LastEvalString" -Type 1 -LogFile $LogFile
    CMTraceLog -Message  "Last Baseline Eval Time Less than 24 hours, and baseline reported compliant, using those results" -Type 1 -LogFile $LogFile
    }



#Get Non-Compliant Items Friendly Names & Log
$NonCompliantNames = ForEach ($PA_Rule in $WaaSNonCompliant)
{($PA_Rule).CIProperties.Name.'#text'}

ForEach ($PA_Rule in $WaaSNonCompliant)
    {
    CMTraceLog -Message  "Hard PreFlight Failure: $($PA_Rule.CIProperties.Name.'#text')" -Type 1 -LogFile $LogFile
    CMTraceLog -Message  "$($PA_Rule.CIProperties.Name.'#text') Needs: $($PA_Rule.ConstraintViolations.ConstraintViolation.SettingInformation.InstanceData.Instance.RuleExpression)" -Type 1 -LogFile $LogFile
    CMTraceLog -Message  "$($PA_Rule.CIProperties.Name.'#text') Has Version: $($PA_Rule.ConstraintViolations.ConstraintViolation.SettingInformation.InstanceData.Instance.CurrentValue)" -Type 1 -LogFile $LogFile
    if ($tsenv)
        {
        $NonCompliantItemName = $PA_Rule.CIProperties.Name.'#text'
        $NonCompliantItemName = $NonCompliantItemName -replace 'Version Mismatch',''
        $NonCompliantItemName = $NonCompliantItemName -replace '\s','_'
        $tsenv.Value("$($NonCompliantItemName)NonCompliant") = "True"
        }
    }



if ($tsenv)
    {
    $tsenv.Value("PreFlight_NonCompliant") = $NonCompliantNames | Out-String
    $tsenv.Value("PreFlight_BaseLineRevision") = $WaaSBaseline.Version| Out-String
    }

CMTraceLog -Message  "Finished $ScriptName Script" -Type 1 -LogFile $LogFile