#$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
#$ComputerName= $tsenv.Value("OSDComputerName")
#$MoveToOU=$tsenv.Value("OUPath")


#Move-ADObject $ComputerName -TargetPath $MoveToOU

Move-ADObject "anc-hwl3dz1" -TargetPath "OU=Test,OU=WSUS Security Groups,OU=Computers,OU=Anc,OU=UAA,DC=ua,DC=ad,DC=alaska,DC=edu"