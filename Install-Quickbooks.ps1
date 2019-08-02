# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Install Quickbooks Support Files
& msiexec /i $ScriptPathParent\ThirdParty\MSMXL6\msxml6_x64.msi /qn | Out-Null
& msiexec /i $ScriptPathParent\ThirdParty\MSMXL6\msxml6_x86.msi /qn | Out-Null
& $ScriptPathParent\ThirdParty\CRT10\QBVCRedist64.exe /S /v/qn | Out-Null
& $ScriptPathParent\ThirdParty\CRT10\VC10RedistX86.exe /S /v/qn | Out-Null
& $ScriptPathParent\ThirdParty\CRT12\vcredist_x64.exe /install /quiet | Out-Null
& $ScriptPathParent\ThirdParty\CRT12\vcredist_x86.exe /install /quiet | Out-Null
& $ScriptPathParent\ThirdParty\ABS\ABSPDF412Setup.exe /s | Out-Null

#Install Quickbooks 2017
& msiexec /i $ScriptPathParent\QBooks\QuickBooks.msi /qn | Out-Null

#Copy Settings File to machine
Copy-Item $ScriptPathParent\ProgramData\Intuit -Destination "C:\ProgramData" -Recurse -Force | Out-Null
