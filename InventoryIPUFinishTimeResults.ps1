#WaaS Info Script Phase 2 of 2.  
#Phase 2 is at end of TS, grabs basic info and writes to registry.
#
#  IPU Keys:
#   IPUReturnStatus
#   IPUReturnCode
#   IPURuntime
#   IPUSetuptime
#   IPUBuild
#   IPUFailedAttempts - IF TS FAILS
#   IPUFailedStepReturnCode
#   IPUFailedStepName
#   WaaS_Stage


#Function to increment the IPUAttemps Key for each run


function Set-RegistryValueIncrement {
    [cmdletbinding()]
    param (
        [string] $path,
        [string] $Name
    )

    try { [int]$Value = Get-ItemPropertyValue @PSBoundParameters -ErrorAction SilentlyContinue } catch {}
    Set-ItemProperty @PSBoundParameters -Value ($Value + 1).ToString() 
}

#Setup TS Environment
try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
}
catch
{
	Write-Verbose "Not running in a task sequence."
}

if ($tsenv)
    {
    $tsBuild = $tsenv.Value("SMSTS_Build")
    #SMSTS_Build is set in the Task Sequence
    $registryPath = "HKLM:\$($tsenv.Value("RegistryPath"))\$($tsenv.Value("SMSTS_Build"))"

    #Gets the Time in Minutes it takes to run Task Sequence  and Writes to Registry
    $Difference = ([datetime]$TSEnv.Value("SMSTS_FinishTSTime")) - ([datetime]$TSEnv.Value("SMSTS_StartTSTime")) 
    $Difference = [math]::Round($Difference.TotalMinutes)
    if ( -not ( test-path $registryPath ) ) {new-item -ItemType directory -path $registryPath -force -erroraction SilentlyContinue | out-null}
    New-ItemProperty -Path $registryPath -Name "IPURunTime" -Value $Difference -force

    #Gets the Time in Minutes it takes to Run the Setup.exe Step and Writes to Registry
    $DifferenceSetup = ([datetime]$TSEnv.Value("SMSTS_FinishUpgradeTime")) - ([datetime]$TSEnv.Value("SMSTS_StartUpgradeTime")) 
    $DifferenceSetup = [math]::Round($DifferenceSetup.TotalMinutes)
    if ( -not ( test-path $registryPath ) ) {new-item -ItemType directory -path $registryPath -force -erroraction SilentlyContinue | out-null}
    if ((Get-Item -Path $registrypath).getValue("IPUSetupTime") -eq $null) {New-ItemProperty -Path $registryPath -Name "IPUSetupTime" -Value $DifferenceSetup -force}


    #Gets CompatScan Results and Write Code & Friendly Name to Registry
    if ($tsenv.Value("_SMSTSOSUpgradeActionReturnCode"))
        {
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
            @{ Err = "800700b7"; Msg = 'File already exists.' }        
            @{ Err = "0"; Msg = 'Windows Setup completed successfully.' }
            )
        

     $ErrorMsg = $winipuret | ? err -eq $hexreturncode  | % Msg
        New-ItemProperty -path $registryPath -Name "IPUReturnStatus" -PropertyType String -Value $ErrorMsg -Force
        #New-ItemProperty -Path $registryPath -Name "IPUReturnCodeDec" -Value $tsenv.Value("_SMSTSOSUpgradeActionReturnCode") -force
        New-ItemProperty -Path $registryPath -Name "IPUReturnCode" -PropertyType String -Value $hexreturncode -Force
        }
        if ($tsenv.Value("_SMSTSOSUpgradeActionReturnCode") -eq $null)
        {New-ItemProperty -path $registryPath -Name "IPUReturnStatus" -PropertyType String -Value "Failed Setup Step" -Force}

    #Update WaaS_Status
    if ((Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\' 'ReleaseID') -eq $tsBuild)
        {New-ItemProperty -Path $registryPath -Name "WaaS_Stage" -Value "Deployment_Success" -force}
        Else 
    {New-ItemProperty -Path $registryPath -Name "WaaS_Stage" -Value "Deployment_Error" -force}
    
    #Add Build Record Info so you know which Build of OS was deployed
    $UBR = (Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuildNumber)+'.'+(Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' UBR)
    New-ItemProperty -Path $registryPath -Name "IPUBuild" -Value $UBR -Force


<#If Fails, 
    1) deletes IPURuntime, IPUSetupTime, IPUBuild
    2) Increments Failed Attempts
    3) Records FailedStepName & LastFailedCode
    4) Updates WaaS Stage
 
     #>
    if ($tsenv.Value("AllStepsSucceded") -eq "False")
        {
        New-ItemProperty -Path $registryPath -Name "WaaS_Stage" -Value "Deployment_Error" -force
        New-ItemProperty -Path $registryPath -Name "IPUFailedStepName" -Value $tsenv.Value("FailedStepName") -force
        New-ItemProperty -Path $registryPath -Name "IPUFailedStepReturnCode" -Value $tsenv.Value("FailedStepReturnCode") -force
        #Delete IPURuntime if exist from previous upgrade (So it doesn't sku results)
        #if ((Get-Item -Path $registrypath).getValue("IPURuntime") -ne $null) {Remove-ItemProperty -Path $registrypath -Name IPURuntime}
        #Delete IPURuntime if exist from previous upgrade (So it doesn't sku results)
        #if ((Get-Item -Path $registrypath).getValue("IPUBuild") -ne $null) {Remove-ItemProperty -Path $registrypath -Name IPUBuild}
        #Delete IPURuntime if exist from previous upgrade (So it doesn't sku results)
        #if ((Get-Item -Path $registrypath).getValue("IPUSetuptime") -ne $null) {Remove-ItemProperty -Path $registrypath -Name IPUSetuptime}

        #Sets IPUFailedAttempts Key and Increments after each Failure.
        Set-RegistryValueIncrement -Path $registryPath -Name IPUFailedAttempts

        }    
    }
