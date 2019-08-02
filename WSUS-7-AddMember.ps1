$Computer = $env:COMPUTERNAME + "$"
ADD-ADGroupMember -identity “CN=Windows 7 WSUS,OU=WSUS Security Groups,OU=Computers,OU=Anc,OU=UAA,DC=ua,DC=ad,DC=alaska,DC=edu” –members $Computer

