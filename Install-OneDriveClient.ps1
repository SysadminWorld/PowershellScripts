<#
    .SYNOPSIS
    Makes sure that the latest version of the OneDrive client is installed correctly for each
    user on the workstation.

    .DESCRIPTION
    <Brief description of script>

    .PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>

    .INPUTS
    None

    .OUTPUTS
    None

    .NOTES
    Version:        1.0.0
    Author:         Chris Axtell (cbaxtell@uaa.alaska.edu)
    Creation Date:  2017-03-31
    Purpose/Change: Initial script development
  
    .EXAMPLE
    Install-OneDriveClient.ps1

#>
#requires -version 1
param
(
  [Parameter(Position=0)]
  [String]$DomainController='ua.ad.alaska.edu',
  [Parameter(Position=1)]
  [String]$Domain='ua.ad.alaska.edu'
)
# ---------------------------------------------------------[Initialisations]--------------------------------------------------------
# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

$Debug=$true
$Verbose=$true
$TestMode=$false

$ServerName = 'anc-fs01.ua.ad.alaska.edu'
$FolderPath = 'Installers\Microsoft'

# Set Verbose preference to display messages when -Verbose flag is used
if($Verbose) {
  $oldverbose = $VerbosePreference
  $script:VerbosePreference = 'Continue'
} else {
  $oldverbose ='SilentlyContinue'
}

# Set debug preference to display messages when -Debug flag is used
If($Debug) {
  $olddebug = $DebugPreference
  $script:DebugPreference = 'Continue'
} else {
  $olddebug ='SilentlyContinue'
}

# Sets PowerShell to configure strict mode for the current scope (and all child scopes). When strict mode
# is on, Windows PowerShell generates a terminating error when the content of an expression, script,
# or script block violates basic best-practice coding rules.
Set-StrictMode -Version Latest

# Sets PowerShell to Execution Policy Scope to unrestricted for only the session that is running this script.
Set-ExecutionPolicy –Scope Process Unrestricted

# ----------------------------------------------------------[Declarations]----------------------------------------------------------

# The client is installed per user typically in a path like C:\Users\<UserName>\AppData\Local\Microsoft\OneDrive
# so we use the localappdata variable to reference the binary path.
$OneDriveClientInstallPath="$($env:localappdata)\Microsoft\OneDrive\onedrive.exe"

# Define the full path to the source of the OneDrive client installer.
# \\ua.ad.alaska.edu\SysVol\ua.ad.alaska.edu\Policies\{C0F55744-CA03-4CD4-9337-6C49F0BAAB2D}\User\Scripts\Logon
#$InstallerPath="\\$($DomainController)\sysvol\$($Domain)\scripts\OneDriveSetup.exe"
#$InstallerPath="\\$($DomainController)\sysvol\$($Domain)\Policies\{C0F55744-CA03-4CD4-9337-6C49F0BAAB2D}\User\Scripts\Logon\OneDriveSetup.exe"
$InstallerPath="\\$($ServerName)\$($FolderPath)\OneDriveSetup.exe"


# Installer command
If ( $TestMode ) {
  $InstallerParameters=''
} else {
  $InstallerParameters='/silent'
}


# --------------------

# Check to see if the script is being run interactively, or via scheduled task.
$script:IsInteractive = [environment]::userinteractive

# Script Author Name
$AuthorName = 'C. Axtell'

# Script Creation Date
$ScriptCreationDate = '3/21/2017'

# Script Version
$ScriptVersion = "1.0.0"

# Stores the full path to this powershell script (e.g. C:\Scripts\ScriptDirectory\ScriptName.ps1)
$ScriptPath =  $MyInvocation.MyCommand.Definition

# Stores the name of this powershell script
$ScriptName = $MyInvocation.MyCommand.Name

# Strips off the trailing '.ps1' value from the script name.
$ScriptName = $ScriptName -replace ".ps1", ""

# Windows environmental variable to retrieve the path to the current user's AppData\Roaming directory
# e.g. c:\Users\<UserName>\AppData\Roaming
$script:LogPath = "$($env:appdata)"

# The log file name is saved to the same directory this script is ran from.
$script:logfile = "$LogPath\$ScriptName-$(get-date -format yyyyMMdd).log"

# Change the integer at the end of this to indicate the number of days to keep past log files for.
$LastLogDate = '{0:yyyyMMdd}' -f (get-date).adddays(-10)

# The name of the oldest log file name to be deleted if found.
$script:OldLogfile = "$LogPath\$ScriptName-$LastLogDate.log"

if (!(Test-Path $script:LogPath)) { New-Item -Path $script:LogPath -ItemType directory -Force }

# Defines the header information that is placed at the begin of the log file.
$script:Separator = @"

$('-' * 25)

"@

$script:FileHeader = @"
$separator
***Application Information***
Filename:       $ScriptName
Created by:     $AuthorName
Version:        $ScriptVersion
Date Created:   $ScriptCreationDate
Last Modified:  $(Get-Date -Date (get-item $scriptPath).LastWriteTime -f MM/dd/yyyy)
$separator
"@

#-----------------------------------------------------------[Functions]------------------------------------------------------------


##########################################################################################
#	Takes any information passed to it and writes the result to a log file.
#	If the log file doesn't exist then it will create.
#
function write-log{
  [CmdletBinding()]
  param
  (
    [string]$info
  )

  # Test to see if the logfile doesn't exist, and if so then create it.
  if(!(Test-Path $logfile)){
    # Enable the following line for debugging purposes only if the log file isn't created
    write-Debug "Logfile doesn't exist, so we'll create it."
    $FileHeader > $logfile
  }
  $info >> $logfile
} # End write-log


function Remove-OldLogFiles {
  [CmdletBinding()]
  param
  (
  )
  
  Write-Verbose 'Checking for old log files to delete...'
  write-log 'Checking for old log files to delete...'

  # Verify if the log file exists
  if ( Test-Path $OldLogfile ) {
    # We found the old log file now we delete it.
    Write-Verbose "`tFound an old log file. Now attempting to delete $oldLogFile"
    Write-log "`tFound an old log file. Now attempting to delete $OldLogfile"
    Remove-Item $OldLogfile
    if ( Test-Path $OldLogfile ) {
      Write-Verbose "`t`tWe were unsuccessful with deleting the old log file $OldLogfile"
      Write-log "`t`tWe were unsuccessful with deleting the old log file $OldLogfile"
    } else {
      Write-Verbose "`t`tWe were successful with deleting the old log file."
      Write-log "`t`tWe were successful with deleting the old log file."
    }
  } else {
    Write-Verbose "`tWe did not find an old log file named $OldLogfile"
    Write-log "`tWe did not find an old log file named $OldLogfile"
  }
  
  Write-Verbose 'Completed cleanup of old log files'
  Write-log 'Completed cleanup of old log files'
} # End of Remove-OldLogFiles


function Enable-DetailFileVersion {
  [CmdletBinding()]
  Param
  (
  )
  
  Update-TypeData -TypeName System.Io.FileInfo -MemberType ScriptProperty -MemberName FileVersionUpdated -Value {
    New-Object System.Version -ArgumentList @(
      $this.VersionInfo.FileMajorPart
      $this.VersionInfo.FileMinorPart
      $this.VersionInfo.FileBuildPart
      $this.VersionInfo.FilePrivatePart
    )
  } 

} # End Enable-DetailFileVersion function


function Get-VersionNumber {
  [CmdletBinding()]
  Param
  (
    [parameter(Position=0, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$FilePath
  )

  Write-Debug "`tStarting function Get-VersionNumber" 
  Write-Debug "`tValue of FilePath: $FilePath"

  $VersionInfo = New-Object -TypeName PSObject

  if ( (Test-Path $($FilePath) ) ) {
    $FileVersion = (Get-Item -Path $($FilePath)).FileVersionUpdated
    
    Write-DEBUG "`tValue of FileVersion: $FileVersion"

    Add-Member -InputObject $VersionInfo -MemberType NoteProperty -Name Major -Value $([version]$FileVersion).Major  # Get major version number
    Add-Member -InputObject $VersionInfo -MemberType NoteProperty -Name Minor -Value $([version]$FileVersion).Minor  # Get minor version number
    Add-Member -InputObject $VersionInfo -MemberType NoteProperty -Name Build -Value $([version]$FileVersion).Build # Get build version number
    Add-Member -InputObject $VersionInfo -MemberType NoteProperty -Name Revision -Value $([version]$FileVersion).MinorRevision  # Get revision version number"

    Write-DEBUG "`tValue of VersionInfo:"
    Write-Debug "`t`tMajor   : $($VersionInfo.Major)"
    Write-Debug "`t`tMinor   : $($VersionInfo.Minor)"
    Write-Debug "`t`tBuild   : $($VersionInfo.Build)"
    Write-Debug "`t`tRevision: $($VersionInfo.Revision)"

    return $versionInfo
  } else {
    Write-Verbose "`tUnable to locate $($FilePath)"
    
    return $null
  }

} # End of funtion Get-VersionNumber


function Compare-Versions {
  [CmdletBinding()]
  Param
  (
    [parameter(Position=0, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [Object]$CurrentVersion,
    [parameter(Position=0, Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [Object]$InstalledVersion
  )
  
  Write-Debug "`tStarting function Compare-Versions"
  Write-Debug "`t`tValue of CurrentVersion:   $($CurrentVersion)"
  Write-Debug "`t`tValue of InstalledVersion: $($InstalledVersion)"

  # Check Major Version first
  If ( $($CurrentVersion.Major) -gt $($InstalledVersion.Major) ) {
    write-verbose "`t`tThe current software is newer than the installed version."
    write-log "`t`tThe current software is newer than the installed version."
    return $true
  } elseif ( $($CurrentVersion.Major) -eq $($InstalledVersion.Major) ) {
    if ( $($CurrentVersion.Minor) -gt $($InstalledVersion.Minor) ) {
      write-verbose "`t`tThe current software is newer than the installed version."
      write-log "`t`tThe current software is newer than the installed version."
      return $true
    } elseif ( $($CurrentVersion.Minor) -eq $($InstalledVersion.Minor) ) {
      if ( $($CurrentVersion.Build) -gt $($InstalledVersion.Build) ) {
        write-verbose "`t`tThe current software is newer than the installed version."
        write-log "`t`tThe current software is newer than the installed version."
        return $true
      } elseif ( $($CurrentVersion.Build) -eq $($InstalledVersion.Build) ) {
        if ( $($CurrentVersion.Revision) -gt $($InstalledVersion.Revision) ) {
          Write-Verbose "`t`tThe current software is newer than the installed version."
          write-log "`t`tThe current software is newer than the installed version."
          return $true
        } elseif ( $($CurrentVersion.Revision) -eq $($InstalledVersion.Revision) ) {
          Write-Verbose "`t`tThe current software is equal to the installed version."
          write-log "`t`tThe current software is equal to the installed version."
          return $false
        } else {
          Write-Verbose "`t`tUnsure of the installed client, so installing the current version"
          write-log "`t`tUnsure of the installed client, so installing the current version"
          return $true
        } # End of Revision version check
      } # End of Build version check
    } # End of Minor version check
  } # End of Major version check


} # End of function Compare-Versions

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Verbose "Script execution started @ $(Get-Date -Format 'F')"
Write-log "Script execution started @ $(Get-Date -Format 'F')"

Write-Debug "Value of logfile: $logfile"

Enable-DetailFileVersion

write-log -info "`tChecking for OneDrive client installer..."
# Check to see if we can access the OneDrive client installer
Try {
  if ( (Test-Path $($InstallerPath) ) ) {
    Write-Verbose "`t`tSuccessfully located the OneDrive client installer, proceeding"
    write-log "`t`tSuccessfully located the OneDrive Client installer, proceeding"
  } else {
    Write-Verbose "`t`tERROR: Unable to locate the OneDrive client installer, existing the script."
    writ-log "`t`tERROR: Unable to locate the OneDrive client installer, existing the script."
    exit 1
  }
} Catch {
    # get error record
    [Management.Automation.ErrorRecord]$e = $_

    # retrieve information about runtime error
    $info = [PSCustomObject]@{
      Exception = $e.Exception.Message
      Reason    = $e.CategoryInfo.Reason
      Target    = $e.CategoryInfo.TargetName
      Script    = $e.InvocationInfo.ScriptName
      Line      = $e.InvocationInfo.ScriptLineNumber
      Column    = $e.InvocationInfo.OffsetInLine
    }
    
    # output information. Post-process collected info, and log info (optional)
    $info
    write-log "`t`tERROR: Unable to connect to file share"
    exit 1
}

Write-Log "`tRetrieving version number of OneDrive client installer"
$CurrentVersion = Get-VersionNumber -FilePath $InstallerPath

Write-Debug "`t`tCurrent OneDrive client version: $CurrentVersion"

write-log "`tRetrieving version number of OneDrive client installed on workstation"
$InstalledVersion = Get-VersionNumber -FilePath $OneDriveClientInstallPath

Write-Debug "`t`tInstalled OneDrive client version: $InstalledVersion"

write-log "`tComparing OneDrive client versions"
$UpdateSoftware = Compare-Versions -CurrentVersion $CurrentVersion -InstalledVersion $InstalledVersion

Write-Debug "`t`tUpdate Software value: $UpdateSoftware"

If ( $UpdateSoftware ) {
  Write-Verbose "`tInstalling OneDrive client"
  write-log "`tInstalling OneDrive client..."
  $Command="$InstallerPath $InstallerParameters"

  If ($PSCmdlet.ShouldProcess("Install Application using $Command started")) {
    # Call the product Install.
    & cmd.exe /c "$Command"
    [Int]$ErrorCode = $LASTEXITCODE
  } # ShouldProcess
  Switch ($ErrorCode) {
    0       {
      Write-Verbose "`t`tInstall command $Command completed successfully."
      write-log "`t`tOneDrive client installation completed successfully."
    }
    1641    {
      Write-Verbose "`t`tInstall command $Command completed successfully and computer is rebooting."
      write-log "`t`tOneDrive client installation completed successfully and computer is rebooting."
    }
    default {
      Write-Verbose "`t`tInstall command $Command failed with error code $ErrorCode."
      write-log "`t`tOneDrive client installation failed with error code $ErrorCode."
    }
  } # ($ErrorCode)

} else {
  Write-Verbose "`tInstalled version of OneDrive client is current"
  write-log "`tInstalled version of OneDrive client is current."
}

Remove-OldLogFiles

Write-Verbose "Script execution Completed @ $(Get-Date -Format 'F')"
Write-log "Script execution Completed @ $(Get-Date -Format 'F')"

# Reset Verbose settings to the previous settings
$VerbosePreference = $oldverbose

# Reset debug settings to the previous settings
$DebugPreference = $olddebug

exit 0