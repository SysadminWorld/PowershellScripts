Function Get-Expiration
{
    Param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$UserName = $([Security.Principal.WindowsIdentity]::GetCurrent()).name.Substring(3,$([Security.Principal.WindowsIdentity]::GetCurrent()).name.Length - 3)
    )
    Process
    {
        $SearchForUser = ([ADSISearcher]”Name=$UserName”).FindAll() | Select *
        If ([string]::IsNullorEmpty($SearchForUser))
        {
            Write-Host "That person doesn't exist in AD. Please try again." -ForegroundColor Red
            Return
        }
        $LastPasswordSet = $($SearchForUser.Properties.pwdlastset)
        $DateofPasswordSet = [datetime]::FromFileTime($LastPasswordSet)
        $MaxPasswordAgeAll = Get-ADDefaultDomainPasswordPolicy | Select MaxPasswordAge
        $MaxAgeDays = $MaxPasswordAge.MaxPasswordAge.Days
        $PasswordExpireDate = (Get-Date $DateofPasswordSet).AddDays($MaxAgeDays)
        $NumberOfDaysLeft = New-TimeSpan -Start (Get-Date) -End $PasswordExpireDate
        $Result = $NumberOfDaysLeft.Days
        $DatePasswordSet = "$($DateofPasswordSet.Month)/$($DateofPasswordSet.Day)/$($DateofPasswordSet.Year)"
        $DateExpiring = "$($PasswordExpireDate.Month)/$($PasswordExpireDate.Day)/$($PasswordExpireDate.Year)"
        If ($UserName -eq ($([Security.Principal.WindowsIdentity]::GetCurrent()).name.Substring(3,$([Security.Principal.WindowsIdentity]::GetCurrent()).name.Length - 3)))
        {
            Write-Host "You last set your password on $($DatePasswordSet). You're password will expire in $Result days on $DateExpiring." -ForegroundColor cyan
        }
        Else
        {
            Write-Host "The password for $UserName was last set on $($DatePasswordSet). It will expire in $Result days on $DateExpiring." -ForegroundColor cyan
        }
    }
}