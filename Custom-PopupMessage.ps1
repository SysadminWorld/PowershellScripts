function New-PopupMessage {
# Return values for reference (https://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx)
 
# Decimal value    Description  
# -----------------------------
# -1               The user did not click a button before nSecondsToWait seconds elapsed.
# 1                OK button
# 2                Cancel button
# 3                Abort button
# 4                Retry button
# 5                Ignore button
# 6                Yes button
# 7                No button
# 10               Try Again button
# 11               Continue button
 
# Define Parameters
[CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # The popup message
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Message,
 
        # The number of seconds to wait before closing the popup.  Default is 0, which leaves the popup open until a button is clicked.
        [Parameter(Mandatory=$false,Position=1)]
        [int]$SecondsToWait = 0,
 
        # The window title
        [Parameter(Mandatory=$true,Position=2)]
        [string]$Title,
 
        # The buttons to add
        [Parameter(Mandatory=$true,Position=3)]
        [ValidateSet('Ok','Ok-Cancel','Abort-Retry-Ignore','Yes-No-Cancel','Yes-No','Retry-Cancel','Cancel-TryAgain-Continue')]
        [array]$ButtonType,
 
        # The icon type
        [Parameter(Mandatory=$true,Position=4)]
        [ValidateSet('Stop','Question','Exclamation','Information')]
        $IconType
    )
 
# Convert button types
switch($ButtonType)
    {
        "Ok" { $Button = 0 }
        "Ok-Cancel" { $Button = 1 }
        "Abort-Retry-Ignore" { $Button = 2 }
        "Yes-No-Cancel" { $Button = 3 }
        "Yes-No" { $Button = 4 }
        "Retry-Cancel" { $Button = 5 }
        "Cancel-TryAgain-Continue" { $Button = 6 }
    }
 
# Convert Icon types
Switch($IconType)
    {
        "Stop" { $Icon = 16 }
        "Question" { $Icon = 32 }
        "Exclamation" { $Icon = 48 }
        "Information" { $Icon = 64 }
    }
 
# Create the popup
(New-Object -ComObject Wscript.Shell).popup($Message,$SecondsToWait,$Title,$Button + $Icon)
}
 
# Close the Task Sequence Progress UI temporarily (if it is running) so the popup is not hidden behind
try
    {
        $TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
        $TSProgressUI.CloseProgressDialog()
    }
Catch {}
$Debug = $False
If (!$Debug) 
{ 
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    $UpgradeText = $tsenv.Value("UpgradeText")
    $UpgradeTimer = $tsenv.Value("UpgradeTimer")
    $UpgradeTitle = $tsenv.Value("UpgradeTitle")
    $UpgradeButton = $tsenv.Value("UpgradeButton")
    $UpgradeIcon = $tsenv.Value("UpgradeIcon")
}
else
{
    $UpgradeText = 'This is a test run'
    $UpgradeTimer = 60
    $UpgradeTitle = 'Test'
    $UpgradeButton = 'Ok'
    $UpgradeIcon = 'Information'
}
 
# Define the parameters.  View the function parameters above for other options.
$Params = @(
    $UpgradeText # Popup message
    $UpgradeTimer                           # Seconds to wait till the popup window is closed
    $UpgradeTitle       # title
    $UpgradeButton                        # Button type
    $UpgradeIcon               # Icon type
    )
 
# Run the function
$ResultFromButton = New-PopupMessage @Params
If ($ResultFromButton -eq 2 )
{
    If (!$Debug){ $tsenv.Value("UpgradeResult") = $ResultFromButton }
    exit 2
}
else
{
    #$ResultFromButton
    exit 0
}
