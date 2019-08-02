<#
# create folders and shares, windows-noob.com 2016/5/14
# 
#>

# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
	Write-Warning "exiting this script."
    Break
}
# specify the drive letter to create shares on...
$SourcesDrive = "D:"
# create a folder
New-Item -Path "$SourcesDrive\UpgradeLogs" -ItemType Directory
# create a share
New-SmbShare –Name UpgradeLogs$ –Path $SourcesDrive\UpgradeLogs -FullAccess EVERYONE