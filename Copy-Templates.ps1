#Remove old templates
Remove-Item -Path 'C:\Program Files (x86)\MicroLab_6_2_18\Templates\*' -Force -Recurse

#Copy New Templates

# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

Copy-Item -Path $ScriptPathParent'\MicroLab Templates\CPSB 315\*.*' -Destination 'C:\Program Files (x86)\MicroLab_6_2_18\Templates' -Force -Recurse

#Copy MSDS Sheets to Public Desktop

Copy-Item -Path $ScriptPathParent\'Desktop SDSs\CPSB 315 SDS Sheets' -Destination 'C:\Users\Public\Desktop' -Force -Recurse
