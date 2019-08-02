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
$EncryptionKeyFile = 'C:\temp\registry-backup070517.reg'
$PasswordFile = 'C:\temp\license-key.txt'
$Password = 'P@ssword1'

Get-Random -Count 32 -InputObject (0..255) | Out-File -FilePath $EncryptionKeyFile
ConvertTo-SecureString -String $Password -AsPlainText -Force | ConvertFrom-SecureString -Key (Get-Content -Path $EncryptionKeyFile) | Out-File -FilePath $PasswordFile

#>


# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

# Use Excryption and keyfile for setting password.
$EncryptionKeyFile = "$ScriptPathParent\registry-backup070517.reg"
$PasswordFile = "$ScriptPathParent\license-key.txt"
$SecurePassword = (Get-Content -Path $PasswordFile | ConvertTo-SecureString -Key (Get-Content -Path $EncryptionKeyFile))
$UserAccount = Get-LocalUser -Name "itsdesktop"
$UserAccount | Set-LocalUser -Password $SecurePassword

