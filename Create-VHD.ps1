<#
    .SYNOPSIS
    Creates a complete backup of the computer prior to imaging it.

    .DESCRIPTION
    Creates a complete backup of the computer in a VHD format so that it can be mounted in Hyper-v in case of missing files.

    .OUTPUTS
    None

    .NOTES
    Version:        1.0.0
    Author:         John Yoakum (jyoakum@alaska.edu)
    Creation Date:  2019-05-15
    Purpose/Change: Initial script development
  
    .EXAMPLE
    Create-VHD.ps1

#>

# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

# Path to store VHD
$StoreLocale = '\\anc-sccm-src01\vhd$'

# VHD File Name
$FileName = $env:COMPUTERNAME

# Full Path for VHD Storage
$FullPath = "$StoreLocale\$FileName.vhd"

# Get the list of available drive information
$OldDrive = Get-PSDrive -p FileSystem

# Retrieve only those drives that have a size bigger than 75GB
$Letters = $OldDrive | Where-Object {$_.Name -ne "X"-and (($_.Used/1gb) + ($_.Free/1gb)) -gt '20'}

# From the list of those drives that are bigger than 75GB, find the drive that currently has a Windows folder in the root.
$NewDrive = $Letters | Where-Object {(Test-Path "$($_.Root)\Windows") -eq $true}

# Assign the correct drive letter to a variable that can be used to put OS on
$DriveLetter = $NewDrive.Name + ":"


# Run Disk2VHD and store the VHD on a network share
& $ScriptPathParent\disk2vhd.exe $DriveLetter $FullPath