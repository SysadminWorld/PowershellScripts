<#
.SYNOPSIS
	Obsolete page file causing high CPU cycles on VDIs after OS version upgrade 
	this script deletes obsolete Page File during win10 build upgrade via CCM task sequence

.DESCRIPTION
	Disables automatic management of the pagefile, then delete olderpage file.
	Defaults is C:\pagefile.sys always with the WFDC envirnment.
	The page file's fully qualified file name "C:\\pagefile.sys"

WMIC Command lines for direct use with TS when there are challanges with this PS
Disable the automatic configuration of the Windows page file with value False
Wmic ComputerSystem set AutomaticManagedPagefile=False
Reboot
Wmic PageFileSet where name="C:\\pagefile.sys" Delete
Reverting back to the automatic page file
Wmic ComputerSystem set AutomaticManagedPagefile=True
Continue with OS upgrade
	#>

$PageFileAMClear = Get-Wmiobject Win32_computersystem -EnableAllPrivileges
$PageFileAMClear.AutomaticManagedPageFile = $false 
$PageFileAMClear.Put()
# Set-WMIInstance -Class Win32_PageFileSetting -Arguments @{name="C:\pagefile.sys";Initialsize=0;MaximumSize=0}
$CurrentPageFile = Get-WmiObject -Query "select * from Win32_PageFileSetting where name= 'C:\\pagefile.sys'"
$CurrentPageFile.delete()
$PageFileAMSet = Get-Wmiobject Win32_computersystem -EnableAllPrivileges
$PageFileAMSet.AutomaticManagedPageFile = $True
$PageFileAMSet.Put()