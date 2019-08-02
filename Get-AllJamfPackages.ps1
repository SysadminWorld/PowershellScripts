[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
$Packages = Invoke-RestMethod -Uri 'https://jamf.uaa.alaska.edu:8443/JSSResource/packages' -Method Get -Credential (Get-Credential) -ContentType "application/xml" -Verbose
#Invoke-WebRequest -Uri 'https://jamf.uaa.alaska.edu:8443/JSSResource/packages' -Method Get -Credential (Get-Credential) -ContentType "application/xml" -Verbose

}
catch {
    $_.Exception | Format-List -Force
}

#$Packages
ForEach ($Package in $Packages.Packages) {
 #$Package.package.name
}

$PackageName = $Package.package.name
$PackageName | Out-File c:\temp\MacPackages.csv