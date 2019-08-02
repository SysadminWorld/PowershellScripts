# Check to see if MMA is connected to OMS
$workspaceId = "64d05b3c-cdbd-496d-9d3c-27507836340b"
$workspaceKey = "cjVHq5F9CeqwEdDdUaWu22GW5DpRvlkOY2ELoB+Q8lygcdyMzBNh89jDJPXMdRlPRIfkBtuid1/OYxYV2ZHnlQ=="

$DEBUGMode = $False

Function Test-UAAOMSConnectionStatus {
    Try
    {
        $MMAgent = New-Object -ComObject AgentConfigManager.MgmtSvcCfg
    }
    Catch
    {
        #Write-Host 'No Microsoft Monitoring Agent Found'
        Return 'Not Installed'
    }
    $WorkSpaceSettings = $MMAgent.GetCloudWorkspaces() | Select workspaceID
    If ( [string]::IsNullOrWhiteSpace($WorkSpaceSettings) )
    {   
        Return 'Not Configured'
    }
    Else
    {
        If ( $WorkSpaceSettings.workspaceID -eq $workspaceId ){
            Return 'Configured'
        }
        Else {
            If ($DEBUGMode){Write-Host "Value of Config Result: $ConfigResult"}
            Return 'Not Configured'
        }
    }
}

Function Set-UAAOMSConfiguration
{
    $MMAgent = New-Object -ComObject AgentConfigManager.MgmtSvcCfg
    $MMAgent.AddCloudWorkspace($workspaceId, $workspaceKey)
    $MMAgent.ReloadConfiguration()
    $ConfigTestResult = Test-UAAOMSConnectionStatus
    Return $ConfigTestResult
}

# ------- Main Body ---------------
$TestCondition = Test-UAAOMSConnectionStatus

If ($TestCondition -eq 'Not Configured')
{
    $ConfigResult = Set-UAAOMSConfiguration
    If ($DEBUGMode){Write-Host "Value of Config Result: $ConfigResult"}
    If ( $ConfigResult -eq 'Configured')
    {
        If ($DEBUGMode){Write-Host 'Returning successful result of attempting to set configuration.'}
        Return $True
    }
    else
    {
        If ($DEBUGMode){Write-Host 'Returning unsuccessful result of attempting to set configuration.'}
        Return $False
    }

}
elseif ($TestCondition -eq 'Configured')
{
    If ($DEBUGMode){Write-Host 'Returning result of already configured'}
    Return $True
}
elseif ($TestCondition -eq 'Not Installed')
{
    If ($DEBUGMode){Write-Host 'Returning result where MMA not installed'}
    Return $False
}
else
{
    If ($DEBUGMode){Write-Host 'Returning Something Went Wrong!!!'}
    Return $False
}
