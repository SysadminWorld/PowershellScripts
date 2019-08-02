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
    
CMTraceLog -Message  "Starting PreFlight WaaS Baseline Gather Script" -Type 1 -LogFile $LogFile

#Trigger WaaS PreAssessment Baseline
$DCM = [WMIClass] "ROOT\ccm\dcm:SMS_DesiredConfiguration"
$WaaSBaseline = Get-WmiObject -Namespace root\ccm\dcm -QUERY "SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName LIKE '%Pre-Assessment'"
$LastEvalTime = $WaaSBaseline.LastEvalTime
$DCM.TriggerEvaluation($WaaSBaseline.Name, $WaaSBaseline.Version)
CMTraceLog -Message  "Last Baseline Eval Time: $LastEvalTime" -Type 1 -LogFile $LogFile
$TimeOut = 1
$TimeOutMax = 300
$Message = "Checking WaaS Baseline Configuration Compliance"
$Step = 1
$MaxStep = 100
do
    {
    If ($TimeOut -gt $TimeOutMax){break}
    $tsPUI.ShowActionProgress(`        $tsenv.Value("_SMSTSOrgName"),`        $tsenv.Value("_SMSTSPackageName"),`        $tsenv.Value("_SMSTSCustomProgressDialogMessage"),`        $tsenv.Value("_SMSTSCurrentActionName"),`        [Convert]::ToUInt32($tsenv.Value("_SMSTSNextInstructionPointer")),`        [Convert]::ToUInt32($tsenv.Value("_SMSTSInstructionTableSize")),`        $Message,`        $Step,`        $MaxStep)
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

CMTraceLog -Message  "Updated Baseline Eval Time: $UpdatedLastEvalTime" -Type 1 -LogFile $LogFile

#Get Baseline CI's that are Non-Compliant
$DCM = [WMIClass] "ROOT\ccm\dcm:SMS_DesiredConfiguration"
$WaaSBaseline = Get-WmiObject -Namespace root\ccm\dcm -QUERY "SELECT * FROM SMS_DesiredConfiguration WHERE DisplayName LIKE '%Pre-Assessment'"
$UserReport = $DCM.GetUserReport($WaaSBaseline.Name,$WaaSBaseline.Version,$null,0)
[XML]$Details = $UserReport.ComplianceDetails
$WaaSNonCompliant = $Details.ConfigurationItemReport.ReferencedConfigurationItems.ConfigurationItemReport | Where-Object {$_.CIComplianceState -eq "NonCompliant"}


#Get Non-Compliant Items Friendly Names & Log
$NonCompliantNames = ForEach ($PA_Rule in $WaaSNonCompliant)
{($PA_Rule).CIProperties.Name.'#text'}
ForEach ($PA_Rule in $WaaSNonCompliant)
    {
    CMTraceLog -Message  "Hard PreFlight Failure: $($PA_Rule.CIProperties.Name.'#text')" -Type 1 -LogFile $LogFile
    CMTraceLog -Message  "$($PA_Rule.CIProperties.Name.'#text') Needs: $($PA_Rule.ConstraintViolations.ConstraintViolation.SettingInformation.InstanceData.Instance.RuleExpression)" -Type 1 -LogFile $LogFile
    CMTraceLog -Message  "$($PA_Rule.CIProperties.Name.'#text') Has Version: $($PA_Rule.ConstraintViolations.ConstraintViolation.SettingInformation.InstanceData.Instance.CurrentValue)" -Type 1 -LogFile $LogFile
    }


if ($tsenv)
    {
    $tsenv.Value("PreFlight_NonCompliant") = $NonCompliantNames | Out-String
    $tsenv.Value("PreFlight_BaseLineRevision") = $WaaSBaseline.Version| Out-String
    }

CMTraceLog -Message  "Finished PreFlight WaaS Baseline Gather Script" -Type 1 -LogFile $LogFile