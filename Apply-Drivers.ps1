#Retrieve the Task Sequence Variable for OSDisk and Drivers
$tsenv_OSDisk = New-Object -COMObject Microsoft.SMS.TSEnvironment
$tsenv_OSDisk.Value("OSDTargetSystemDrive")

$tsenv_Drivers = New-Object -COMObject Microsoft.SMS.TSEnvironment
$tsenv_Drivers.Value("Drivers01")

& Dism.exe /Image:$($tsenv_OSDisk) /Driver:$($tsenv_Drivers)\ /Recurse | Out-Null

