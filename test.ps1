$OSVersion = Get-WmiObject Win32_OperatingSystem | Select-Object Version
If ($OSVersion -like "6.1*") {
$PhysicalAdapter = Get-WmiObject win32_NetworkAdapter | Select Name, InterfaceIndex, AdapterType | Where-Object { $_.AdapterType -like "Ethernet*" }
}
else {
$PhysicalAdapter = Get-NetAdapter -physical 
}

Foreach ($Adapter in $PhysicalAdapter ){
# Check to see if there is a NIC set up with a static IP
$NICs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {($_.InterfaceIndex -eq $Adapter.ifIndex) -and ($_.DHCPEnabled -eq $false) } | Select-Object -Property [a-z]* 
If (-not [string]::IsNullOrEmpty($NICs))
{
    #Write-Host "The IP Address is: " $NICs.IPAddress
    #$NICs
    $ip = ($NICs.IPAddress[0]) 
    $gateway = $NICs.DefaultIPGateway 
    $subnet = $NICs.IPSubnet[0] 
    $dns = $NICs.DNSServerSearchOrder
    # Set the variables needed for WinPE
    #$TSEnv.Value("OSDAdapter0DNSServerList") = $dns
    #$TSEnv.Value("OSDAdapter0EnableDHCP") = 'False'
    #$TSEnv.Value("OSDAdapter0Gateways") = $gateway
    #$TSEnv.Value("OSDAdapter0IPAddressList") = $ip
    #$TSEnv.Value("OSDAdapter0SubnetMask") = $subnet
    #$TSEnv.Value("OSDAdapterCount") = 1
}
}
Write-Host "The IP Address is: " $ip
Write-Host "The Default Gateway Address is: " $gateway
Write-Host "The Subnet Address is: " $subnet
Write-Host "The DNS Servers are: " $dns
