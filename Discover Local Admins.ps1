#Discovery Script for discovery who is current local admin

$useraffinity = gwmi -Namespace root\ccm\policy\machine -Class ccm_useraffinity
$users = “administrator”,”UA\Domain Admins”,”UA\sccm-naa”,"itsdesktop","UA\uaa_its_desktop","UA\uaa_testctrworksta"
foreach ($useraff in $useraffinity)
{ $users += $useraff.ConsoleUser }

$members = net localgroup administrators | where {$_ -AND $_ -notmatch “command completed successfully”} | select -skip 4
New-Object PSObject -Property @{
Computername = $env:COMPUTERNAME
Group = “Administrators”
Members=$members
} | out-null

$adminusers = $true
foreach ($useradm in $users)
{
if (!($members -contains $useradm))
{ 
$adminusers = $false
break;
}
}

foreach ($useradm in $members)
{
if (!($users -contains $useradm))
{ 
$adminusers = $false
break;
}
}
write-host $adminusers