Set-Location "049:\Application\Patch My PC Applications"
$ApplicationsWithoutIcons = (Get-CMApplication | Select LocalizedDisplayName,SDMPackageXML) | Where-Object {($_ -notlike "*<Icon id=*") -and ($_ -like "*PatchMyPC*")} 
