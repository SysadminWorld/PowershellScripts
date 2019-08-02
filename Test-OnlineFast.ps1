<#
==========================================================================================
Name:              Find-Printers.ps1

Description:       Find all printer information on the network based on the printers listed
                   in SCCM.

Operation:         Example usage:  .\Find-Printers.ps1

Version:           2.0

Created On:        30 April 2019 by John Yoakum

Last Modified:     

Language:          PowerShell
                   .NET Framework

==========================================================================================
#>
Function FastPing($System)
{

    $CurrentErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    $Obj = New-Object System.Net.NetworkInformation.Ping
    $ClearToTest = $false
    $Status = $null
    $Device = $null
    $ADResult = $null

    If (([Bool]([IPAddress]$System)) -eq $true) {
        $Device = $System
        $ClearToTest = $true
    }

    If ($ClearToTest -eq $false) {
        $ADResult = Get-ADComputer $System -Properties "ipv4address"

        If ($ADResult -ne $null) {
            $Device = $ADResult.IPv4Address
            $ClearToTest = $true
        }
    }
    
    If ($ClearToTest -eq $true) {
        $Status = ($Obj.send($Device, 100)).status
    } Else {
        $Status = "Error"
    }

    Return $Status
    $ErrorActionPreference = $CurrentErrorAction
}

# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

$ErrorActionPreference = 'SilentlyContinue'

$PrinterIPs = Import-Csv -Path $ScriptPathParent\PrinterMappings.csv | Get-Unique -AsString

$OnlinePrinters = @()
$PrinterInfo = @()
$PrinterID = $PrinterIPs | Sort-Object | Get-Unique -AsString

$snmp = New-Object -ComObject olePrn.OleSNMP


ForEach ($Printer in $PrinterID){
    $PingPrinters = FastPing($($Printer).IPAddress)
    $OnlinePrinters += [pscustomobject]@{
        Address = $Printer.IPAddress
        Online = $PingPrinters
        }
}

$OnlinePrinters = $OnlinePrinters | Where-Object { $_.Online -eq "Success" } | Get-Unique -AsString

ForEach ($OnlinePrinter in $OnlinePrinters)
{
        $addr = $OnlinePrinter.Address
        $model = $null
        $loc = $null
        $snmp.open($($OnlinePrinter).Address, 'public', 2, 3000) 
        #$snmp.open("137.229.156.67", 'public', 2, 3000)
        $model = $snmp.Get('.1.3.6.1.2.1.25.3.2.1.3.1')
        $loc = $snmp.Get('.1.3.6.1.2.1.1.6.0')
        #Write-Host $addr, $model, $loc
        $PrinterInfo += [pscustomobject]@{
            IP = $addr
            Model = $model
            Location = $loc
            }

}

$PrinterInfo = $PrinterInfo | Where-Object { $_.Model -ne $null } | Get-Unique -AsString
$PrinterInfo | Export-Csv -Path c:\Temp\UAA_Printers.csv
