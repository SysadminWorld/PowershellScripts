$regexa = '.+Domain="(.+)",Name="(.+)"$' $regexd = '.+LogonId="(\d+)"$'  $logon_sessions = @(gwmi win32_logonsession -ComputerName $env:COMPUTERNAME) $logon_users = @(gwmi win32_loggedonuser -ComputerName $env:COMPUTERNAME)  $session_user = @{}  $logon_users |% { $_.antecedent -match $regexa > $nul ;$username = $matches[2] ;$_.dependent -match $regexd > $nul ;$session = $matches[1] ;$session_user[$session] += $username }   $currentUser = $logon_sessions |%{ $loggedonuser = New-Object -TypeName psobject $loggedonuser | Add-Member -MemberType NoteProperty -Name "User" -Value $session_user[$_.logonid] $loggedonuser | Add-Member -MemberType NoteProperty -Name "Type" -Value $_.logontype$loggedonuser | Add-Member -MemberType NoteProperty -Name "Auth" -Value $_.authenticationpackage ($loggedonuser  | where {$_.Type -eq "2" -and $_.Auth -eq "Kerberos"}).User } $currentUser = $currentUser | select -UniqueWrite-Host $CurrentUser#Check if running in TS
try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    #$tsenv.CloseProgressDialog()
}
catch
{
	Write-Verbose "Not running in a task sequence."
}


#Update $RegistryPath Value for your Environment. 
$RegistryPath = "HKLM:\$($tsenv.Value('RegistryPath'))"$CurrentOSBuild = Get-ItemPropertyValue 'HKLM:SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion' 'Releaseid'New-ItemProperty -Path "$RegistryPath\$CurrentOSBuild" -Name OSUninstall_UserAccount -Value $CurrentUser -Force