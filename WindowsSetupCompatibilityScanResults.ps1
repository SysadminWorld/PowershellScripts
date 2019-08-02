<#
# This script will search for a value and return the corresponding value in the second field.
# It will then popup a Windows setup compatibility scan results window in plain text using PowerShell based on the _SMSTSOSUpgradeActionReturnCode variable
# niall brady 2016/5/14
#
# The following variable _SMSTSOSUpgradeActionReturnCode from https://technet.microsoft.com/en-us/library/mt629380.aspx will be used to determine the return code.
# Here are the KnownErrorCodes to popup messages against via https://technet.microsoft.com/en-us/library/mt629396.aspx#BKMK_UpgradeOS
#
# MOSETUP_E_COMPAT_SCANONLY (OxC1900210) No compatibility issues ("success").
# MOSETUP_E_COMPAT_INSTALLREQ_BLOCK (0xC1900208) Actionable compatibility issues.
# MOSETUP_E_COMPAT_MIGCHOICE_BLOCK (0xC1900204) Selected migration choice is not available. For example, an upgrade from Enterprise to Professional.
# MOSETUP_E_COMPAT_SYSREQ_BLOCK (OxC1900200) Not eligible for Windows 10.
# MOSETUP_E_COMPAT_INSTALLDISKSPACE_BLOCK (0xC190020E) Not enough free disk space.
#>

Function LogWrite
{
   Param ([string]$logstring)
   Add-content $Logfile -value $logstring
   write-host $logstriing
}

$Logfile = "C:\Windows\Temp\WindowsSetupCompatScan.log"
$Manufacturer=((Get-WmiObject -Class win32_computersystem).Manufacturer)
$Model=((Get-WmiObject -Class win32_computersystem).Model)
$Date=Get-Date
LogWrite "Starting Windows Setup compatibility scan results script"
LogWrite "The following hardware was detected: $Manufacturer $Model"

#Hide the progress dialog
$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

# unrem the next line to test manually thanks Nickolaj for the [int64] tip
#[int64]$decimalreturncode="3247440400"
#
# rem the next two lines to test manually
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
write-host "The task sequence step returned the following return code: $tsenv.Value("_SMSTSOSUpgradeActionReturnCode")"
[int64]$decimalreturncode=$tsenv.Value("_SMSTSOSUpgradeActionReturnCode")
#
# convert the decimal value to HEX
$hexreturncode="{0:X0}" -f [int64]$decimalreturncode
LogWrite "The original decimal returncode was: $decimalreturncode"
LogWrite "The converted HEX returncode is: $hexreturncode"

$row = 0
$hexreturncode=$hexreturncode.ToUpper()
$KnownErrorCodes = @(("C1900210","C1900208","C1900204","C1900200","C190020E"),("No compatibility issues.","Actionable compatibility issues.","Selected migration choice is not available. For example, an upgrade from Enterprise to Professional.","Not eligible for Windows 10.","Not enough free disk space."))

foreach($value in $KnownErrorCodes)

{
$col = 0
#LogWrite "" -ForegroundColor white
#LogWrite "$hexreturncode" -nonewline -ForegroundColor green
#LogWrite ""
  foreach ($element in $value) 
  {
      #write-host "Searching row[$row]col[$col]" -nonewline -ForegroundColor white
      #write-host "Row #" $row "Col #" $col "Value =" $value[$col]
      #write-host "$hexreturncode".ToUpper()

      If ($value[$col].Contains($hexreturncode))
  
        {   LogWrite "Found value at $row $col" -ForegroundColor red
            # add +1 to skip down to the corresponding row...
            $row++
            $result = $KnownErrorCodes[$row][$col]
            break
            #exit
        }
 else
{$result="Unknown Value: "}
  $col++    
  }  
  $row++
  # quit after searching the first row, if you want to search more rows remove the If group
  If ($row -ge 1)
  {
    LogWrite "" 
    LogWrite "The corresponding value to return is: " -nonewline
    LogWrite -foregroundcolor Green $result
    LogWrite "Windows 10 compatibility scan ran on: $date ending script."
  break
  }
  else
  {}
 } 
if ($hexreturncode -ne "C1900210")
{
# now show a popup message to the end user
[System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)
[Windows.Forms.MessageBox]::Show(“Sorry, but this computer isn't ready to be upgraded right now. Please inform your IT department that the result of the Windows Setup compatibility scan was: $Result ('$hexreturncode')”, “Windows 10 setup comptability scan”, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
write-host "There was a problem detected in the compatibility scan, therefore we will fail the task sequence..."
  $tsenv.Value("WindowsSetupCompatibilityScan") = "FAILED"
break
}
 else
 
  {
  write-host "There was no problem detected in the compatibility scan, therefore continuing with the task sequence..."
  $tsenv.Value("WindowsSetupCompatibilityScan") = "OK"}

