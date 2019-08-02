$PatchMyPCApps = Get-CMApplication | Where {$_.SDMPackageXML -like "*PatchMyPC*"}
ForEach ($App in $PatchMyPCApps )
{
Write-Host "Removing... $($App.LocalizedDisplayName)" -ForegroundColor Cyan
Get-CMApplication -name $App.LocalizedDisplayName | Remove-CMApplication -Force
Write-Host "Removed... $($App.LocalizedDisplayName)" -ForegroundColor Green
}