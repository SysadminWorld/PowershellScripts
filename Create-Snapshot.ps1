$Debug = $False

# Create Archive folder if it doesn't exist for this log file and for sending logs
$TestPath = Test-Path -path c:\Archive
If (!$TestPath) { $LogsDirectory = New-Item -Path 'c:\Archive' -Force -ItemType Directory }
Else { $LogsDirectory = 'C:\Archive' }

function Write-CMLogEntry {
    param (
        [parameter(Mandatory = $true, HelpMessage = 'Value added to the log file.')]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [parameter(Mandatory = $true, HelpMessage = 'Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('1', '2', '3')]
        [string]$Severity,
        [parameter(Mandatory = $false, HelpMessage = 'Name of the log file that the entry will written to.')]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = 'CreateISO.log'
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
		
    # Construct time stamp for log entry
    $Time = -join @((Get-Date -Format 'HH:mm:ss.fff'), '+', (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
		
    # Construct date for log entry
    $Date = (Get-Date -Format 'MM-dd-yyyy')
		
    # Construct context for log entry
    $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
		
    # Construct final log entry
    $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""PackageMapping"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
		
    # Add value to log file
    try {
        Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
    }
    catch {
        Write-Warning -Message "Unable to append log entry to CreateISO.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}

# Stores the full path to the parent directory of this powershell script
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

Write-CMLogEntry -Value '***********************************************************' -Severity 1
Write-CMLogEntry -Value 'Beginning creation of ISO file for backup' -Severity 1

$OS = Get-WmiObject Win32_OperatingSystem | Select *

$DriveLetter = $OS.SystemDrive
Write-CMLogEntry -Value "Found the operating system at $DriveLetter" -Severity 1

$FileName = $env:COMPUTERNAME
Write-CMLogEntry -Value "Set the filename for the snapshot file to $FileName" -Severity 1

$ComputerPath = Test-Path -path \\anc-sccm-src01.ua.ad.alaska.edu\vhd\$env:COMPUTERNAME
If (!$ComputerPath) { New-Item -Path "\\anc-sccm-src01.ua.ad.alaska.edu\vhd\$env:COMPUTERNAME" -Force -ItemType Directory }
$ValidPath = Test-Path -Path \\anc-sccm-src01.ua.ad.alaska.edu\vhd\$env:COMPUTERNAME -IsValid

If ( $ValidPath )
{
    Write-CMLogEntry -Value 'Not enough space on current drive, creating the snapshot on the network share.' -Severity 1
    $StoreLocale = "\\anc-sccm-src01.ua.ad.alaska.edu\vhd\$env:COMPUTERNAME"
    Write-CMLogEntry -Value "Creating the ISO in $StoreLocale" -Severity 1
    $MakeISO = $True
}
else
{
    Write-CMLogEntry -Value 'Unable to connect to network share. Skipping the creation of a backup snapshot.' -Severity 2
    $MakeISO = $False
}

# Full Path for VHD Storage
$FullPath = "$StoreLocale\$FileName.sna"
Write-CMLogEntry -Value "Set the full filename including path to $FullPath" -Severity 1

If ( !$Debug ){
    If ( $MakeISO )
    {
        & $ScriptPathParent\snapshot64.exe $DriveLetter $FullPath --exclude:\Archive --LogFile:$LogsDirectory\Snapshot.txt | Out-Null
    }
}
Write-CMLogEntry -Value "Finished creating the snapshot. The snapshot is stored at $FullPath" -Severity 1