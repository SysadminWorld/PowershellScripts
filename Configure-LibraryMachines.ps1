<#
    .SYNOPSIS
    This script is the master installation and configuration script for the Consortium Library Installations.

    .DESCRIPTION
    This script will configure the Consortium Library Public Computers for their use.

    .INPUTS
    None. 

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Configure-LibraryMachines.ps1
    FALSE

    .NOTES
    File Name	: Configure-LibraryMachines.ps1
    Author		: John Yoakum - jyoakum@alaska.edu
    Requires	: PowerShell v3.0 or later
#>

# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

# Remove unneeded Printers
Remove-Printer -Name "Microsoft XPS Writer"
Remove-Printer -Name "Fax"
Remove-Printer -Name "Send to OneNote 16"
Remove-Printer -Name "Send to OneNote 2016"

#Copy Files to c:\ for scheduled tasks and for start menu and task bar

# Copy and Install USB Disk Eject
Copy-Item $ScriptPathParent\"USB Disk Eject" -Destination "C:\Program Files" -Recurse -Force | Out-Null

# Copy Files for Scheduled Tasks
Copy-Item $ScriptPathParent\shutdown.bat -Destination "C:\shutdown.bat" -Recurse -Force | Out-Null
Copy-Item $ScriptPathParent\deldoc_win10.bat -Destination "C:\deldoc_win10.bat" -Recurse -Force | Out-Null



