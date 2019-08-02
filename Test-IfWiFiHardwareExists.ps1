#requires -version 3
<#
    .SYNOPSIS
    This script checks to see if the computer has any IEEE 802.11 wireless network interfaces.
    If so it returns TRUE, otherwise it returns FALSE.

    .DESCRIPTION
    The script uses the Get-NetAdapeter command and searches for any interface types that
    equal to a value of 71 which represents an IEEE 802.11 wireless network interface.
    If it finds one it returns TRUE, otherwise it returns FALSE.

    .INPUTS
    None. You cannot pipe objects to Test-IfWiFiHardwareExists.

    .OUTPUTS
    Boolean value. Test-IfWiFiHardwareExists returns a boolean value of TRUE or FALSE.

    .EXAMPLE
    C:\PS> Test-IfWiFiHardwareExists
    FALSE

    .EXAMPLE
    C:\PS> Test-IfWiFiHardwareExists
    TRUE

    .LINK
    https://docs.microsoft.com/en-us/powershell/module/netadapter/get-netadapter?view=win10-ps

    .LINK
    https://docs.microsoft.com/en-us/windows/desktop/api/ifdef/ns-ifdef-_net_luid_lh


    .NOTES
    File Name	: Test-IfWiFiHardwareExists.ps1
    Author		: Chris Axtell - cbaxtell@uaa.alaska.edu
    Requires	: PowerShell v3.0 or later
#>

# Test to see if WiFi network exists, and cast the results to boolean.
$result = [bool]$(Get-NetAdapter | ? {$_.InterfaceType -eq '71'})

return $result