# Function to get the DellPSProvider and load it for purposes of this script

#Set Error Action so that the Try-Catch works
$ErrorActionPreference = 'Stop'

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

$WOLCurrentValue = Get-Item -Path Dellsmbios:\PowerManagement\WakeOnLan | select CurrentValue

If ($WOLCurrentValue.CurrentValue -eq "Disabled") 
    { 
        $Result = "Disabled"
    }
Else 
    {
        $Result = "Enabled"
    }

$Result

