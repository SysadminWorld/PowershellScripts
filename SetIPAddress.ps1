
#Create the function to set the IPAddress
function Set-StaticIPAddress ($strIPAddress, $strSubnet, $strGateway, $strDNSServer1, $strDNSServer2) {
    $NetworkConfig = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IpEnabled = 'True'"
    $NetworkConfig.EnableStatic($strIPAddress, $strSubnet)
    $NetworkConfig.SetGateways($strGateway, 1)
    $NetworkConfig.SetDNSServerSearchOrder(@($strDNSServer1, $strDNSServer2))
}
#Tell Powershell to use the headers of the csv file to make them fields
$NameOfComputer = @()
$IPAddress = @()
$DefaultGateway = @()
$SubnetMask = @()

#Find the Scriptpath and use it for importing the csv file
$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
Write-host "My directory is $dir"
$MyFile=$dir+"\ManagedPrint.csv"

#Import the csv file and process the table
Import-Csv $MyFile -Delimiter ","
    ForEach-Object {
        $NameOfComputer += $_.NameOfComputer
        $IPAddress += $_.IPAddress
        $DefaultGateway += $_.DefaultGateway
        $SubnetMask += $_.SubnetMask
    }

Write-Host "Finished processing CSV"

#Search the array for the computer name and populate the variables.
if ($NameOfComputer -contains $env:computername)
    {
    $Where = [array]::IndexOf($NameOfComputer, $env:computername)
    $IP = $IPAddress[$Where]
    $DG = $DefaultGateway[$Where]
    $SM = $SubnetMask[$Where]
    #Set the execution Policy
    #Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

    #Run the function to set the static IP Address
    #Set-StaticIPAddress $IP $SM $DG "137.229.138.85" "137.229.138.94"

}
    Write-Host $IP
    Write-Host $DG
    Write-Host $SM