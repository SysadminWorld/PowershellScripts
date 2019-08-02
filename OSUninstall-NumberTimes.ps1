function Set-RegistryValueIncrement {
    [cmdletbinding()]
    param (
        [string] $path,
        [string] $Name
    )

    try { [int]$Value = Get-ItemPropertyValue @PSBoundParameters -ErrorAction SilentlyContinue } catch {}
    Set-ItemProperty @PSBoundParameters -Value ($Value + 1).ToString() 
}

#Check if running in TS
try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    #$tsenv.CloseProgressDialog()
}
catch
{
	Write-Verbose "Not running in a task sequence."
}


#Update $RegistryPath Value for your Environment. 
$RegistryPath = "HKLM:\$($tsenv.Value('RegistryPath'))"
$OSUninstallBuild = Get-ItemPropertyValue -Path "$RegistryPath" -Name OSUninstall
$RegistryPathFull = "$RegistryPath\$OSUninstallBuild"

if ( -not ( test-path $RegistryPathFull ) ) { 
    new-item -ItemType directory -path $RegistryPathFull -force -erroraction SilentlyContinue | out-null
}
#Writes the Start Time to a Key in the Parent (WaaS) with the name of the TS, so we can keep track of when we've run which TS.
Set-RegistryValueIncrement -Path $RegistryPathFull -Name OSUninstall_NumberTimes