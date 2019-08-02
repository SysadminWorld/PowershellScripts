#Evaluate where computer is being put
If (($Location=$env:computername.Substring(4,3) -eq "BMH") -or ($Location=$env:computername.Substring(4,3) -eq "ISB")) {

#Create and Set the Instructor Account and Password
$computername = $env:computername
$Location=$env:computername.Substring(4,3)
$username = 'Instructor'
$password = 'Instructor' + $Location + '17'
$desc = 'Local Admin Account for Instructors'
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

#Create and set the Student Account
#$computername = $env:computername
#$username = 'Student'
#$desc = 'Local Admin Account for Instructors'
#$computer = [ADSI]"WinNT://$computername,computer"
#$user = $computer.Create("user", $username)
#$user.description = $desc
#$user.setinfo()
#$user.UserFlags = 65536
#$user.SetInfo()
#$group = [ADSI]("WinNT://$computername/users,group")
#$group.add("WinNT://$username,user")
}
