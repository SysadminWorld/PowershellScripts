# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

# Offline application of app associations
#$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
#$DriveLetter = $TsEnv.Value("DriveToInstall")
#$DriveLetter = $TsEnv.Value("OSDisk")
#& Dism.exe /Image:$DriveLetter /Import-DefaultAppAssociations:$ScriptPathParent\appassociations.xml

# Online Application of App Associations
& Dism.exe /Online /Import-DefaultAppAssociations:$ScriptPathParent\appassociations.xml