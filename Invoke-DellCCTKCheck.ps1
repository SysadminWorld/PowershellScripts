<#	
  .DESCRIPTION
    Used to detect the version of CCTK compatible with your Dell system during
    OS deployment tasks calling the CCTK BIOS applicaiton

  .NOTES
      FileName:    Invoke-DellCCTKCheck.ps1
      Author:      Maurice Daly
      Contact:     @MoDaly_IT
      Created:     2018-07-13
      Updated:     2018-07-18
#>

# Functions

BEGIN 
{
  try {
    $TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Continue
  }
  catch [System.Exception] {
    Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object"; break
  }
}
PROCESS {
  # Set Logs Directory
  $LogsDirectory = Join-Path -Path $TSEnvironment.Value("_SMSTSLogPath") -ChildPath "Temp"
  
  function Write-CMLogEntry {
    param (
      [parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")]
      [ValidateNotNullOrEmpty()]
      [string]$Value,
      [parameter(Mandatory = $true, HelpMessage = "Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
      [ValidateNotNullOrEmpty()]
      [ValidateSet("1", "2", "3")]
      [string]$Severity,
      [parameter(Mandatory = $false, HelpMessage = "Name of the log file that the entry will written to.")]
      [ValidateNotNullOrEmpty()]
      [string]$FileName = "ApplyDellCCTK.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
    
    # Construct time stamp for log entry
    $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
    
    # Construct date for log entry
    $Date = (Get-Date -Format "MM-dd-yyyy")
    
    # Construct context for log entry
    $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
    
    # Construct final log entry
    $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""ApplyDellCCTK"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
    
    # Add value to log file
    try {
      Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
      Write-Warning -Message "Unable to append log entry to ApplyDellCCTK.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
  }
  
  Write-CMLogEntry -Value "Staritng Dell CCTK compatibility check" -Severity 1
  $CCTKVersion = (Get-ItemProperty .\CCTK.exe | select -ExpandProperty VersionInfo).ProductVersion
  Write-CMLogEntry -Value "Running Dell CCTK version $CCTKVersion on host system" -Severity 1
  $CCTKExitCode = (Start-Process cctk.exe -Wait -PassThru).ExitCode
  Write-CMLogEntry -Value "Reading Dell CCTK running output" -Severity 1
  if (($CCTKExitCode -eq "141") -or ($CCTKExitCode -eq "140")) {
    Write-CMLogEntry -Value "Non WMI-ACPI BIOS detected. Setting CCTK legacy mode" -Severity 2
    $CCTKPath = Join-Path -Path $((Get-Location).Path) -ChildPath "Legacy"
  }
  else {
    Write-CMLogEntry -Value "WMI-ACPI BIOS detected" -Severity 1
    $CCTKPath = (Get-Location).Path
  }
  Write-CMLogEntry -Value "Setting DellCCTKPath task sequence variable" -Severity 1
  $TSEnvironment.Value("DellCCTKPath") = $CCTKPath
  Write-CMLogEntry -Value "Dell CCTK will be access from $CCTKPath" -Severity 2
}