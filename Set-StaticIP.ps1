$OSVersion = Get-WmiObject Win32_OperatingSystem | Select-Object Name
If (($OSVersion.Name -like "Microsoft Windows 7*") -or ($OSVersion.Name -like "Microsoft Windows 8*")) {
    
    $PhysicalAdapter = Get-WmiObject win32_NetworkAdapter | Select Name, InterfaceIndex, AdapterType | Where-Object { $_.AdapterType -like "Ethernet*" }

    Foreach ($Adapter in $PhysicalAdapter ){
    # Check to see if there is a NIC set up with a static IP
    $NICs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {($_.IfIndex -eq $Adapter.ifIndex) -and ($_.DHCPEnabled -eq $false) } | Select-Object -Property [a-z]* 

    # Register the Task Sequence COM object
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    
    If (-not [string]::IsNullOrEmpty($NICs))
        {

        $ip = ($NICs.IPAddress[0]) 
        $gateway = $NICs.DefaultIPGateway 
        $subnet = $NICs.IPSubnet[0] 
        $dns = $NICs.DNSServerSearchOrder
        
        # Set the variables needed for WinPE
        $TSEnv.Value("OSDAdapter0DNSServerList") = $dns
        $TSEnv.Value("OSDAdapter0EnableDHCP") = 'False'
        $TSEnv.Value("OSDAdapter0Gateways") = $gateway
        $TSEnv.Value("OSDAdapter0IPAddressList") = $ip
        $TSEnv.Value("OSDAdapter0SubnetMask") = $subnet
        $TSEnv.Value("OSDAdapterCount") = 1
        }
    }
    Write-Host "The Windows 7/8 IP Address is: " $ip
    Write-Host "The Windows 7/8 Default Gateway Address is: " $gateway
    Write-Host "The Windows 7/8 Subnet Address is: " $subnet
    Write-Host "The Windows 7/8 DNS Servers are: " $dns
}
else {
    $PhysicalAdapter = Get-NetAdapter -physical -erroraction 'silentlycontinue'
    
    Foreach ($Adapter in $PhysicalAdapter ){
    
    # Check to see if there is a NIC set up with a static IP
    $NICs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object {($_.InterfaceIndex -eq $Adapter.ifIndex) -and ($_.DHCPEnabled -eq $false) } | Select-Object -Property [a-z]* 
    
    # Register the Task Sequence COM object
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    
    If (-not [string]::IsNullOrEmpty($NICs))
        {
        $ip = ($NICs.IPAddress[0]) 
        $gateway = $NICs.DefaultIPGateway 
        $subnet = $NICs.IPSubnet[0] 
        $dns = $NICs.DNSServerSearchOrder
        
        # Set the variables needed for WinPE
        $TSEnv.Value("OSDAdapter0DNSServerList") = $dns
        $TSEnv.Value("OSDAdapter0EnableDHCP") = 'False'
        $TSEnv.Value("OSDAdapter0Gateways") = $gateway
        $TSEnv.Value("OSDAdapter0IPAddressList") = $ip
        $TSEnv.Value("OSDAdapter0SubnetMask") = $subnet
        $TSEnv.Value("OSDAdapterCount") = 1
        }
    }
    Write-Host "The Windows 10 IP Address is: " $ip
    Write-Host "The Windows 10 Default Gateway Address is: " $gateway
    Write-Host "The Windows 10 Subnet Address is: " $subnet
    Write-Host "The Windows 10 DNS Servers are: " $dns
}
