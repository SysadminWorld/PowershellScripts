#This script will be used to uninstall programs (in this case from UC133)

#Uninstall Bluebeam 2018.1
& MsiExec.exe /X {7F5E49F6-A466-4553-B9E0-53D7380944E3} | Out-Null

#Uinstall Quickbooks
& MsiExec.exe /I {B52E01F1-D34E-4381-B590-28DFF3C0B647} | Out-Null

#Uinstall Quickbooks Premier: Accountant Edition 2017
& msiexec.exe /I {B52E01F1-D34E-4381-B590-28DFF3C0B647} UNIQUE_NAME="accountant" QBFULLNAME="QuickBooks Premier: Accountant Edition 2017" ADDREMOVE=1 | Out-Null

#Uninstall Quickbooks Runtime Redistributabe
& MsiExec.exe /I {F2A4F809-2DE6-4D27-888B-4D2BB8DAF20E} | Out-Null

#Uninstall Quickbooks VC10_Debug
& MsiExec.exe /I {2421E8FE-AE35-493A-94F5-66307E006ECF} | Out-Null


