# Requires -RunAsAdministrator
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = 'High'
)]
#Param(
#    [parameter(
#        Mandatory = $true
#    )]
#    [ValidateScript({
#        Test-Path -Path $_
#    })]
#    [string]$StorePath,
#    
#    [parameter(
#        Mandatory = $true
#    )]
#    [string]$DomainSID
#)

$StorePath = "\\anc-sccm-dist01.ua.ad.alaska.edu\State\%COMPUTERNAME%"
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$DomainSID = ([System.DirectoryServices.AccountManagement.UserPrincipal]::Current).SID.Value
#Write $DomainSID


$SID         = (Get-WmiObject Win32_UserProfile | Where-Object {$_.SID -like "$DomainSID*"} | 
    Select-Object SID, Localpath, @{name="LastUsed";Expression={$_.ConvertToDateTime($_.LastUseTime)}} | 
    Sort LastUsed -Descending)[0].SID
$Username    = (New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount]).Value
$StoreName   = $Username.Split('\')[1]
$StoreFolder = (Get-Item -Path $StorePath\$StoreName* | Sort-Object Name -Descending).Name | Select-Object -First 1

if ($PSCmdlet.ShouldProcess("$StorePath\$StoreFolder")) {
    .\loadstate.exe $StorePath\$StoreFolder /i:migdocs.xml /i:migapp.xml /v:5 /l:$env:TEMP\USMTLoad.log /progress:$env:TEMP\USMTLoadProgress.log /c
}