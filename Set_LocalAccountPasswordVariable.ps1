<#
.SYNOPSIS
    Asks the end user for a password for the local admin account and stores it in a variable that is used later during the task sequence.
.DESCRIPTION
    This script will ask the technician for a new local account password during OSD which will then call another script later in the task sequence that uses this one and sets the new local itsdesktop password, allowing for each area to designate thier own password.
.EXAMPLE
    .\Set-LocalAccountPasswordVariable.ps1
.NOTES
    FileName:    Set-SPSSInstall.ps1
    Author:      John Yoakum
    Created:     2018-11-08
    
    Version history:
    1.0.0 - (2018-11-08) Script created

#>
<#
PromptForUsername v1
-----------------
This script prompts for input during a task sequence, and sets the input as a TS variable.
#>
 
# Close the TS UI temporarily
$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()
 
# Prompt for input
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$TSPassword = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the new password for the itsdesktop account", "Password prompt", "eg P@ssw0rd1")
 
# Set the TS variable
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$tsenv.Value("TSPassword") = $TSPassword