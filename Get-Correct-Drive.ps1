# Get the list of available drive information
$OldDrive = Get-PSDrive -p FileSystem

# Retrieve only those drives that have a size bigger than 75GB
$Letters = $OldDrive | Where-Object {$_.Name -ne "X"-and (($_.Used/1gb) + ($_.Free/1gb)) -gt '75'}

# From the list of those drives that are bigger than 75GB, find the drive that currently has a Windows folder in the root.
$NewDrive = $Letters | Where-Object {(Test-Path "$($_.Root)\Windows") -eq $true}

# Assign the correct drive letter to a variable that can be used to put OS on
$DriveLetter = $NewDrive.Name + ":"

# Register the Task Sequence COM object
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

# Set the TS Variable to use a particular drive letter for use in the apply operating system drive letter
$TSEnv.Value("DriveToInstall") = $DriveLetter