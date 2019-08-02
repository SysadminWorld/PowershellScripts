#Add a local user account for print release
$computername = $env:computername
$username = 'ERAdmin'
$password = 'CERCAdmin7602!'
$desc = 'Local Admin Account for Print Release'
$computer = [ADSI]"WinNT://$computername,computer"
$user = $computer.Create("user", $username)
$user.SetPassword($password)
$user.Setinfo()
$user.description = $desc
$user.setinfo()
$user.UserFlags = 65536
$user.SetInfo()
$group = [ADSI]("WinNT://$computername/administrators,group")
$group.add("WinNT://$username,user")