
$KeyFile = "C:\temp\AES.key"
$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

$PasswordFile = "C:\temp\itsdesktopaccount.txt"
$KeyFile = "C:\temp\AES.key"
$Key = Get-Content $KeyFile
$Password = "C@mpu51Tdt907" | ConvertTo-SecureString -AsPlainText -Force #| Out-File $PasswordFile
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile



#$PasswordFile = '$ScriptPathParent\itsdesktopaccount.txt'
#$KeyFile = '$ScriptPathParent\AES.key'
$key = Get-Content $KeyFile
$SecurePassword = Get-Content $PasswordFile 
$SecurePassword | ConvertTo-SecureString -Key $key
$SecurePassword | ConvertTo-SecureString -Key $Key
$SecurePassword2 = ConvertFrom-SecureString -SecureString $SecurePassword -Key $key


$EncryptionKeyFile = 'C:\temp\registry-backup070517.reg'
$PasswordFile = 'C:\temp\license-key.txt'
$Password = 'C@mpu51Tdt907'

Get-Random -Count 32 -InputObject (0..255) | Out-File -FilePath $EncryptionKeyFile
ConvertTo-SecureString -String $Password -AsPlainText -Force | ConvertFrom-SecureString -Key (Get-Content -Path $EncryptionKeyFile) | Out-File -FilePath $PasswordFile
$SecurePassword = (Get-Content -Path $PasswordFile | ConvertTo-SecureString -Key (Get-Content -Path $EncryptionKeyFile))
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

#Import-PfxCertificate -FilePath C:\tmp\BrowserCertificate.p12 -Password (Get-Content -Path C:\tmp\pass.txt |
#ConvertTo-SecureString -Key (Get-Content -Path C:\tmp\registry-backup070517.key)) -CertStoreLocation Cert:\CurrentUser\My -Exportable

