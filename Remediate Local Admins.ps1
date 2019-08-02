#Remediate local admins

$useraffinity = gwmi -Namespace root\ccm\policy\machine -Class ccm_useraffinity

$users = “administrator”,”UA\Domain Admins”,”UA\sccm-naa”,"itsdesktop","UA\uaa_its_desktop","UA\uaa_testctrworksta"

foreach ($useraff in $useraffinity) { $users += $useraff.ConsoleUser }

 

$domain = $env:USERDOMAIN

$adsi = [ADSI]”WinNT://./administrators,group”

 

$members = net localgroup administrators | where {$_ -AND $_ -notmatch “command completed successfully”} | select -skip 4

New-Object PSObject -Property @{

 Computername = $env:COMPUTERNAME

 Group = “Administrators”

 Members=$members

} | out-null

 

foreach ($useradm in $users)

{

    if ((([Array]$members) -contains $useradm) -eq $false)

    {

        $adsi.Add(“WinNT://$Domain/” + ($useradm -Replace (“$($domain)\\”,””)) + “,group”)

    }

}

 

foreach ($useradm in $members)

{ 

    if ((([Array]$users) -contains $useradm) -eq $false)

    {

        try { $adsi.Remove(“WinNT://$Domain/” + ($useradm -Replace (“$($domain)\\”,””))) } 

catch { $adsi.Remove(“WinNT://$useradm”) }

    }

}