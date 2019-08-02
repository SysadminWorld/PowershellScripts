# Register the Task Sequence COM object
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

# Set a Task Sequence Variable to state which drive to install windows on
$tsenv.Value("CurrentOS") = $env:SystemDrive