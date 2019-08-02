$DebugMode = $false

# Set Password and set as secure string
$itsdesktop = 'C@mpu51Tdt907'
$SecurePass = ConvertTo-SecureString -String $itsdesktop -AsPlainText -Force

$UserAccount=$null

# Powershell to find and set local itsdesktop account password.
if ( $DebugMode ) { Write-Host 'Finding if ITSDESKTOP exists' }

$UserAccount = Get-LocalUser | Where-Object {$_.Name -eq 'itsdesktop'}

If ($UserAccount -ne $null)
{
    Try
    {
        if ( $DebugMode ) { Write-Host 'Found account, updating password and settings' }
        Microsoft.PowerShell.LocalAccounts\Set-LocalUser -Name itsdesktop -AccountNeverExpires -Description 'Local Tech Account' -FullName 'ITS Desktop' -Password $SecurePass -PasswordNeverExpires $true
    }
    Catch
    {
        if ( $DebugMode ) { Write-Host 'Found Account, but failed to update with values' }
        Return $False
    }
    if ( $DebugMode ) { Write-Host 'Found account and updated values' }
    Return $True
}
else
{
    Try
    {
        if ( $DebugMode ) { Write-Host 'Account not found, creating new account' }
        Microsoft.PowerShell.LocalAccounts\New-LocalUser -Name itsdesktop -Password $SecurePass -AccountNeverExpires -Description 'Local Tech Account' -FullName 'ITS Desktop' -PasswordNeverExpires
    }
    Catch
    {
        if ( $DebugMode ) { Write-Host 'Account not found, failed to create new account' }
        $AccountExists = $False
    }

    If ($AccountExists -ne $False)
    {
        Try
        {
            if ( $DebugMode ) { Write-Host 'Account created, attempting to add to local admin group' }
            Add-LocalGroupMember -Group 'Administrators' -name 'itsdesktop'
        }
        Catch
        {
            if ( $DebugMode ) { Write-Host 'Account created, failed to add to local group' }
            Return $False
        }

        if ( $DebugMode ) { Write-Host 'Account Created and successfully added to local group' }
        Return $True
    }
    else
    {
        if ( $DebugMode ) { Write-Host 'Failed to create account' }
        Return $False
    }  
}