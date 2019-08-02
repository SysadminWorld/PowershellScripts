If ($Instructor=$env:computername.Substring($env:computername.Length - 3,3) -eq "SCR") {
.\vSolutionLinkSetup_x64.exe /S
}
If ($Instructor=$env:computername.Substring($env:computername.Length - 2,2) -eq "00") {
.\vSolutionLinkSetup_x64.exe /S
}