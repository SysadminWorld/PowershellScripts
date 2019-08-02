# Function to get the DellPSProvider and load it for purposes of this script
Function Get_Dell_BIOS_Settings
 {
  $WarningPreference='silentlycontinue'
  If (Get-Module -ListAvailable -Name DellBIOSProvider)
   {} 
  Else
   {
    Install-Module -Name DellBIOSProvider -Force
   }
  get-command -module DellBIOSProvider | out-null
  $Script:Get_BIOS_Settings = get-childitem -path DellSmbios:\ | select-object category | 
  foreach {
  get-childitem -path @("DellSmbios:\" + $_.Category)  | select-object attribute, currentvalue 
  } 
   $Script:Get_BIOS_Settings = $Get_BIOS_Settings |  % { New-Object psobject -Property @{
    Setting = $_."attribute"
    Value = $_."currentvalue"
    }}  | select-object Setting, Value 
   $Get_BIOS_Settings
 }  

# Check to see if BIOS Password is set
$IsPasswordSet = (Get-Item -Path DellSmbios:\Security\IsAdminPasswordSet).currentvalue 
If($IsPasswordSet -eq $true)
 {
  write-host "Password is configured"
 }
Else
 {
  write-host "No BIOS password"
 } 

# Change the Function Lock and Number Lock Setting without a password
Set-Item -Path Dellsmbios:\POSTBehavior\FnLock -Value Disabled
Set-Item -Path Dellsmbios:\POSTBehavior\NumLock -Value Enabled 

# Change the Function Lock and Number Lock Setting with a password
$MyPassword = "P@$$w0rd"
Set-Item -Path Dellsmbios:\POSTBehavior\FnLock -Value Disabled -Password $MyPassword
Set-Item -Path Dellsmbios:\POSTBehavior\NumLock -Value Enabled -Password $MyPassword

# Change list of settings from a CSV file.
$CSV_File = "D:\BIOS_Checker\BIOS_Change.csv"
$Get_CSV_Content = import-csv $CSV_File
$Dell_BIOS = get-childitem -path DellSmbios:\ | foreach {
get-childitem -path @("DellSmbios:\" + $_.Category)  | select-object attribute, currentvalue, possiblevalues, PSChildName}   
ForEach($New_Setting in $Get_CSV_Content)
 { 
  $Setting_To_Set = $New_Setting.Setting 
  $Setting_NewValue_To_Set = $New_Setting.Value 
  ForEach($Current_Setting in $Dell_BIOS | Where {$_.attribute -eq $Setting_To_Set})
   { 
    $Attribute = $Current_Setting.attribute
    $Setting_Cat = $Current_Setting.PSChildName
    $Setting_Current_Value = $Current_Setting.CurrentValue
 
    If (($IsPasswordSet -eq $true))
     {   
      $Password_To_Use = $MyPassword
      & Set-Item -Path Dellsmbios:\$Setting_Cat\$Attribute -Value $Setting_NewValue_To_Set -Password $Password_To_Use
       
     }
    Else
     {
      & Set-Item -Path Dellsmbios:\$Setting_Cat\$Attribute -Value $Setting_NewValue_To_Set         
     }        
   }  
 }  