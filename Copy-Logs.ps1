# Copy logs from WinPE so that they are available to email later.

# Initialize the TS Environment
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

# Get the Current Logs Directory
$LogsDirectory = $Script:tsenv.Value("_SMSTSLogPath")

# Create Folder to store logs
$NewPath = New-Item -Path $($Script:tsenv.Value("DriveToInstall"))\Windows\CCM\Logs\OSDeploymentLogs -ItemType Directory -Force

# Copy files to new directory
Copy-Item -Path $LogsDirectory\*.* -Destination $NewPath -Recurse
 
