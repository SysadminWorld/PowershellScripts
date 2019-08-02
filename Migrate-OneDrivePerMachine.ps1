<#
.SYNOPSIS
    Install a fresh Per Machine installation of OneDrive or migrate a current installation.
   
.DESCRIPTION
    Install a fresh Per Machine installation of OneDrive or migrate a current installation.
    You have the option to download OneDrive in the minimum supported build directly from Microsoft or use local source files.
    The script also sets the update ring to Insiders. This is to ensure that future fixes for the Per Machine installation is applied.
    
.NOTES
    Filename: Migrate-OneDrivePerMachine.ps1
    Version: 1.1
    Author: Martin Bengtsson
    Blog: www.imab.dk
    Twitter: @mwbengtsson

#>

[CmdletBinding()]
param(
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$NoSourceFiles,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$SourceFiles
)

# Parameters for the OneDrive installation
$InstallParams = "/allusers /quiet"
# Path for OneDrive.exe post installation
$InstalledPath = "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe"

if ($PSBoundParameters["NoSourceFiles"]) {
    Write-Output "No Source Files parameter selected"
    # Official download URL to the minimum supported OneDrive build (19.043.0304.0003)
    $DownloadURL = "https://go.microsoft.com/fwlink/?linkid=2083517"
    # Save the OneDriveSetup.exe into C:\Windows\Temp
    $OneDriveSetup = "$ENV:windir\Temp\OneDriveSetup.exe"

    # Try downloading the OneDriveSetup.exe file
    try {
        Write-Output "Downloading OneDriveSetup.exe and saving it to $OneDriveSetup"
        Invoke-WebRequest -Uri $DownloadURL -OutFile $OneDriveSetup
    }

    catch {
        Write-Output "Error in downloading OneDriveSetup.exe" ; break
    }

    # Continue if the OneDriveSetup.exe file was downloaded
    if (Test-Path -Path $OneDriveSetup) {
    
        if (-NOT(Test-Path -Path $InstalledPath)) {
            Write-Output "OneDrive is not installed already. Installing OneDrive from $OneDriveSetup"
            try {
                # Waiting for the process here seems to wait indefinitely (OneDriveSetup.exe seems to spawn several processes)
                $RunInstall = Start-Process -FilePath $OneDriveSetup -PassThru -ArgumentList $InstallParams
                $Running = $true	
                    # Instead waiting for OneDriveSetup to complete with other means
                    do {
                        Write-Output "Installing OneDrive for Business. Hang on..."
	                    Start-Sleep -Seconds 10
                        if ((Get-Process "OneDriveSetup" -ErrorAction SilentlyContinue)) {
		                    $Running = $true
        		        }
                        else {
                           $Running = $false 
                        }
        
                    } while ($Running -eq $true)
            }
            catch {
                Write-Output "Error installing OneDrive" ; break
            }
        }
        else {
            Write-Output "OneDrive seems to be installed already"
        }
    }
    else {
        Write-Output "Something is not right. OneDriveSetup.exe was not located on $OneDriveSetup" ; break
    }
}

if ($PSBoundParameters["SourceFiles"]) {
    Write-Output "Source Files parameter selected. Assuming OneDriveSetup exists locally"
    $runningDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $OneDriveSetup = "OneDriveSetup.exe"
    if (-NOT(Test-Path -Path $InstalledPath)) {
        try {
            # Waiting for the process here seems to wait indefinitely (OneDriveSetup.exe seems to spawn several processes)
            $RunInstall = Start-Process -FilePath $runningDir\$OneDriveSetup -PassThru -ArgumentList $InstallParams
            $Running = $true	
            # Instead waiting for OneDriveSetup to complete with other means
            do {
                Write-Output "Installing OneDrive for Business using local source files. Hang on..."
	            Start-Sleep -Seconds 10
                if ((Get-Process "OneDriveSetup" -ErrorAction SilentlyContinue)) {
		            $Running = $true
                }
                else {
                    $Running = $false 
                }
        
            } while ($Running -eq $true)
        }
        catch {
            Write-Output "Error installing OneDrive using local source files. Please check if OneDriveSetup.exe exists in the source file folder" ; break
    
        }
    }
    else {
        Write-Output "OneDrive seems to be installed already"
    }
}

# Do following if OneDrive is found on the new location
if (Test-Path -Path $InstalledPath) {
    Write-Output "OneDrive is installed locally in $InstalledPath"
    Write-Output "Configuring OneDrive update ring to Insiders through local registry settings"
    $RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
    $Policy = "GPOSetUpdateRing"
    # Create a local policy configuring OneDrive update ring to Insiders. This is currently recommended in order to receive additional fixes
    try {
        New-ItemProperty -Path $RegistryPath -Name $Policy -Value 4 -PropertyType "DWORD" -Force | Out-Null
    }

    catch {
        Write-Output "Failed to make local changes to registry"
    }

}
else {
    Write-Output "Something is not right - OneDrive was not found in $InstalledPath"

}