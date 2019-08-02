# Set the execution Policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope CurrentUser

# Define if we're in debug mode or not
$DebugMode = 'FALSE'

# Check to see if the script is being run interactively
$script:IsInteractive = [environment]::userinteractive

# Define the primary and secondary DNS servers that we want to configure the workstation to use.
$DnsServer1 = '137.229.138.85'
$DnsServer2 = '137.229.138.94'

#Find the Scriptpath and use it for importing the csv file
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

If ( $IsInteractive ) { Write-host "My directory is $dir" }
$MyFile=$dir+'\ManagedPrint.csv'

# If we're in Debug mode we hard set the hostname variable to a value we know is in
# the assignment list since we may be working on the script on a workstation
# that is not a print release station.
# In non-debug mode we set the hostname variable to the name of the machine the
# script is running on.
if ( $DebugMode -eq 'TRUE' ){
  $HostName = 'anc-fccmp32'
} else {
  $HostName = $env:computername
} 

# **************************************************************
# ********************* START OF FUNCTIONS *********************
# **************************************************************

#Create the function to set the IPAddress
function Set-StaticIPAddress  {
  param
  (
    [string]$strIPAddress,
    [string]$strSubnet,
    [string]$strGateway,
    [string]$strDNSServer1,
    [string]$strDNSServer2
  )
  Write-Host 'Setting workstation with static IP assignment'

  If ( $DebugMode -eq 'TRUE' ) {
    Write-Host "[DEBUG] IP Address     : $strIPAddress"
    Write-Host "[DEBUG] Subnet Mask    : $strSubnet"
    Write-Host "[DEBUG] Default Gateway: $strGateway"
    Write-Host "[DEBUG] DNS Server 1   : $strDNSServer1"
    Write-Host "[DEBUG] DNS Server 2   : $strDNSServer2"
  }
  # Retrieve the current settings of the active network interface
  $NetworkConfig = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IpEnabled = 'True'"
    
  $NetworkConfig.EnableStatic($strIPAddress, $strSubnet)
  $NetworkConfig.SetGateways($strGateway, 1)
  $NetworkConfig.SetDNSServerSearchOrder(@($strDNSServer1, $strDNSServer2))
  $NetworkConfig.SetDynamicDNSRegistration('FALSE')

} # End of Set-StaticIPAddress function

# **************************************************************
# ********************** END OF FUNCTIONS **********************
# **************************************************************

#Import the csv file and process the table
Write-host "Importing list of machine IP assignments from $MyFile"

# Check to see if the file with the ip assignments can be found
If ( Test-Path $MyFile ) {
  $MachineIpAssignmentList = Import-Csv $MyFile
  Write-Host 'Finished importing list of machine IP assginments'
} else {
  Write-Host "Unable to locate the $MyFile file containing the list of machine IP assignments"
  exit 1
}

Write-Host "Searching machine IP assignment list for match with: $HostName"
$MachineIpAssignment = $MachineIpAssignmentList | Where-Object {$_.NameOfComputer -eq $HostName}

If ( $MachineIpAssignment ){
  # If we've successfully found a match then we're going to lookup the appropirate network information
  Write-Host "IP Address     : $($MachineIpAssignment.IPAddress)"
  Write-Host "Default Gateway: $($MachineIpAssignment.DefaultGateway)"
  Write-Host "Subnet Mask    : $($MachineIpAssignment.SubnetMask)"
  
  #Run the function to set the static IP Address
  Set-StaticIPAddress -strIPAddress $($MachineIpAssignment.IPAddress) -strSubnet $($MachineIpAssignment.SubnetMask) -strGateway $($MachineIpAssignment.DefaultGateway) -strDNSServer1 $DnsServer1 -strDNSServer2 $DnsServer2
  
} else {
  Write-Host "WARNING: Unable to locate IP assignment for a machine named $HostName"
}