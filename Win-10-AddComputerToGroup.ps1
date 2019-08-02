$CompuerNameToTest = "$env:computername"
$GroupToMoveTo = "Windows 10 WSUS"
$ADWebS = New-WebServiceProxy -Uri http://anc-sccm-dist01.ua.ad.alaska.edu/uaadeploy/ad.asmx?WSDL
$ComputerExistsInAd = $ADWebS.AddComputerToGroup("$GroupToMoveTo", "$CompuerNameToTest")
 
#Write-Host "The Computer $CompuerNameToTest was added to group: $GroupToMoveTo"