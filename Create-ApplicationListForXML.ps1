$Apps = Get-CMApplication | Select -Property LocalizedDisplayName,SDMPackageXML
$Apps = $Apps | Sort-Object -Property LocalizedDisplayName
#New-Item c:\Temp\AllApplications_TSRef.txt
#New-Item C:\Temp\AllApplications_SoftwareRef.txt
$XMLPathTS = "c:\Temp\AllApplications_TSRef.txt"
$XMLPathRef = "c:\Temp\AllApplications_SoftwareRef.txt"
ForEach ($App in $Apps)
{
    $NewGUID = New-Guid
    #$DataforXML += [pscustomobject]@{GUID = $NewGUID;AppName = $App.LocalizedDisplayName}
    $GUID = $Application.Guid
    $Name = $App.LocalizedDisplayName
    $Value = '<Application ID="' + $NewGUID + '" Label="' + $Name + '" Name="' + $Name + '" />"'
    $Value2 = '<SoftwareRef Id="' + $NewGUID + '" /> <!-- ' + $name + '-->'
    Write-Host "Adding $Name to the text file now" -foregroundcolor cyan
    #Add-Content -Path $XMLPath -Value $Name
    Add-Content -Path $XMLPathTS -Value $Value
    Add-Content -Path $XMLPathRef -Value $Value2
    #Add-Content -Path $XMLPath -Value ([xml]$App.SDMPackageXML).AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location
}
