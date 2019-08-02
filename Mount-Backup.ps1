$Debug = $False

# Stores the full path to the parent directory of this powershell script
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

If (!$Debug)
{
    # Close the TS UI temporarily
    $TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
    $TSProgressUI.CloseProgressDialog()
} 
# Prompt for input
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$Mode = [Microsoft.VisualBasic.Interaction]::MsgBox("Would you like to open the User Interface?","YesNo","User Interface?")
If ( $Mode -eq "No" )
{
    $ComputerName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the Computer Name of the machine whose drive you want to mount.", "Computer Name", "$($env:COMPUTERNAME)")

    $PathExists = Test-Path "\\anc-sccm-src01.ua.ad.alaska.edu\vhd\$($ComputerName)\$($ComputerName).sna" -IsValid
    If ( !$PathExists )
    {
        [Microsoft.VisualBasic.Interaction]::MsgBox("That Computer Name doesn't have a backup associated with it.",1,"No Backup Found")
    }
    else
    {
        $DriveLetter = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the drive letter you wish to mount this backup to.", "Drive Letter", "eg f:")
        $PathToBackup = "\\anc-sccm-src01.ua.ad.alaska.edu\vhd\$($ComputerName)\$($ComputerName).sna"

        & $ScriptPathParent\snapshot64.exe $PathToBackup $DriveLetter -V | Out-Null
    }
}
else
{
    & $ScriptPathParent\snapshot64.exe
}