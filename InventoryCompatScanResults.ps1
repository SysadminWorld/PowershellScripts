#WaaS Info Script CompatScan
#Phase 1 is at start of TS, grabs basic info and writes to registry.
#
#  CompatScan Keys:
#   CompatScanLastRun
#   CompatScanAttempts
#   CompatScanRunTime
#   CompatScanDownloadTime
#   CompatScanReturnStatus
#   CompatScanReturnCode
#   WaaS_Stage

#NOTE, CompatScanHardBlock & CompatScanVPN are individual Steps in the TS, which is why they are not here.


#Creates Function to Set how many times the TS Runs
function Set-RegistryValueIncrement {
    [cmdletbinding()]
    param (
        [string] $path,
        [string] $Name
    )

    try { [int]$Value = Get-ItemPropertyValue @PSBoundParameters -ErrorAction SilentlyContinue } catch {}
    Set-ItemProperty @PSBoundParameters -Value ($Value + 1).ToString() 
}

#Connects to TS Environment and Creates (confirms) Registry Stucture in place for the Win10 Upgrade Build.
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$tsBuild = $tsenv.Value("SMSTS_Build")
$registryPath = "HKLM:\$($tsenv.Value("RegistryPath"))\$($tsenv.Value("SMSTS_Build"))"

if ( -not ( test-path $registryPath ) ) { 
    new-item -ItemType directory -path $registryPath -force -erroraction SilentlyContinue | out-null
}

#Gets TS Start Time and Records to Registry
New-ItemProperty -Path $registryPath -Name "CompatScanLastRun" -Value $TSEnv.Value("SMSTS_StartTSTime") -Force

#Increments the ammount of times the Precache CompatScan TS runs
Set-RegistryValueIncrement -Path $registryPath -Name CompatScanAttempts


#Gets the Time in Minutes it takes to run the CompatScan and Writes to Registry

$Difference = ([datetime]$TSEnv.Value("SMSTS_FinishTSTime")) - ([datetime]$TSEnv.Value("SMSTS_StartTSTime")) 
$Difference = [math]::Round($Difference.TotalMinutes)
if ( -not ( test-path $registryPath ) ) {new-item -ItemType directory -path $registryPath -force -erroraction SilentlyContinue | out-null}
New-ItemProperty -Path $registryPath -Name "CompatScanRunTime" -Value $Difference -force

#Gets the Time in Minutes it takes to Download Cache Items and Writes to Registry
$DifferenceDown = ([datetime]$TSEnv.Value("SMSTS_FinishTSDownTime")) - ([datetime]$TSEnv.Value("SMSTS_StartTSDownTime")) 
$DifferenceDown = [math]::Round($DifferenceDown.TotalMinutes)
if ( -not ( test-path $registryPath ) ) {new-item -ItemType directory -path $registryPath -force -erroraction SilentlyContinue | out-null}
if ((Get-Item -Path $registrypath).getValue("CompatScanDownloadTime") -eq $null) {New-ItemProperty -Path $registryPath -Name "CompatScanDownloadTime" -Value $DifferenceDown -force}


if ($tsenv.Value("_SMSTSOSUpgradeActionReturnCode"))
    {
    #Gets CompatScan Results and Write Code & Friendly Name to Registry
    [int64] $decimalreturncode = $tsenv.Value("_SMSTSOSUpgradeActionReturnCode")
    #[int64] $hexreturncode = 0xC1900210
    $hexreturncode = "{0:X0}" -f [int64]$decimalreturncode

    $WinIPURet = @(
        @{ Err = "C1900210"; Msg = 'No compatibility issues.'}
        @{ Err = "C1900208"; Msg = 'Incompatible apps or drivers.' }
        @{ Err = "C1900204"; Msg = 'Selected migration choice is not available.' }
        @{ Err = "C1900200"; Msg = 'Not eligible for Windows 10.' }
        @{ Err = "C190020E"; Msg = 'Not enough free disk space.' }
        @{ Err = "C1900107"; Msg = 'Unsupported Operating System.' }
        @{ Err = "8024200D"; Msg = 'Update Needs to be Downloaded Again.' }
    )

     $ErrorMsg = $winipuret | ? err -eq $hexreturncode  | % Msg
        New-ItemProperty -path $registryPath -Name "CompatScanReturnStatus" -PropertyType String -Value $ErrorMsg -Force
        #New-ItemProperty -Path $registryPath -Name "CompatScanReturnCodeDec" -Value $tsenv.Value("_SMSTSOSUpgradeActionReturnCode") -force
        New-ItemProperty -Path $registryPath -Name "CompatScanReturnCode" -PropertyType String -Value $hexreturncode -force
    }
#Adding key for WaaS Stage
if ( $hexreturncode -eq "C1900210") 
    {
    if ( -not ( test-path $registryPath ) ) {
        new-item -ItemType directory -path $registryPath -force -erroraction SilentlyContinue | out-null
        }
    New-ItemProperty -Path $registryPath -Name "WaaS_Stage" -Value "Ready_for_Scheduling" -force }
    Else {
    New-ItemProperty -Path $registryPath -Name "WaaS_Stage" -Value "Precache_Compat_Scan_Failure" -force
    }