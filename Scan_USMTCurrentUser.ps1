# Requires -RunAsAdministrator
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = 'Medium'
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


$SID       = (Get-WmiObject Win32_UserProfile | Where-Object {$_.SID -like "$DomainSID*"} | 
    Select-Object SID, Localpath, @{name="LastUsed";Expression={$_.ConvertToDateTime($_.LastUseTime)}} | 
    Sort LastUsed -Descending)[0].SID
$Username  = (New-Object System.Security.Principal.SecurityIdentifier($SID)).Translate([System.Security.Principal.NTAccount]).Value
$StoreName = $Username.Split('\')[1]
$StoreTime = Get-Date -Format "yyyy-MM-dd_HH-mm"

if ($PSCmdlet.ShouldProcess("$StorePath\$($StoreName)_$($StoreTime)")) {
    .\scanstate.exe $StorePath\$($StoreName)_$($StoreTime) /i:migdocs.xml /i:migapp.xml /vsc /uel:5 /ue:* /ui:$($Username) /v:5 /l:$env:TEMP\USMTScan.log /progress:$env:TEMP\USMTScanProgress.log /c
}

