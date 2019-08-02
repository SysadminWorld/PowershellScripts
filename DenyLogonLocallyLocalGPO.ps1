[cmdletbinding()]
param( 
    $LocalGroupName = 'DenyLogonLocally',
    $RightToRemove = 'SeDenyInteractiveLogonRight'
)

Net LocalGroup /add $LocalGroupName

$GroupSID = Get-LocalGroup -Name $LocalGroupName | % SID | % Value

$tempFile = [io.path]::GetRandomFileName() + ".inf"

@"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeDenyInteractiveLogonRight = *$GroupSID
"@ | out-file -FilePath $tempFile -Encoding unicode


secedit.exe /configure /db "$($LocalGroupName).sdb" /cfg $tempFile 
# it would be a good idea to redirect the output from this program to a log

# remove-item -Path $tempFile
