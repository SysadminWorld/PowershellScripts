<#
.SYNOPSIS
    Resets Local itsdesktop password
.DESCRIPTION
    This sript will set the local itsdesktop account password to the one chosen in the task sequence allowing dynamic passwords and not requiring to release current itsdesktop password to everybody.
.EXAMPLE
    .\Set-LocalAccountPassword.ps1
.NOTES
    FileName:    Set-SPSSInstall.ps1
    Author:      John Yoakum
    Created:     2018-11-08
    
    Version history:
    1.0.0 - (2018-11-08) Script created

#>
<# Section to apply password via UI++
# Get Current Environment Information
$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$Password = $tsenv.Value("TSPassword")
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
$UserAccount = Get-LocalUser -Name "itsdesktop"
$UserAccount | Set-LocalUser -Password $SecurePassword
#>

<# Use this section to generate a password file and a key file to be used with this script.
$KeyFile = "C:\temp\AES.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile
$PasswordFile = "C:\temp\Password.txt"
$KeyFile = "C:\temp\AES.key"
$Key = Get-Content $KeyFile
$Password = "P@ssword1" | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
#>
# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

# Use Excryption and keyfile for setting password.
$PasswordFile = "$ScriptPathParent\itsdesktopaccount.txt"
$KeyFile = "$ScriptPathParent\AES.key"
$key = Get-Content $KeyFile
$SecurePassword = Get-Content $PasswordFile | ConvertTo-SecureString -Key $key


$PasswordTest = ConvertFrom-SecureString $SecurePassword 
#$UserAccount = Get-LocalUser -Name "itsdesktop"
#$UserAccount | Set-LocalUser -Password $SecurePassword

