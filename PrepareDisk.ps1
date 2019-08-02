<#
    Company: Onevinn AB
    Name: PrepareDisk.ps1
    Author: Johan Schrewelius
    Date: 2019-05-03
    Version: 1.0
    Usage: Run as prestart command in ConfigMgr Boot image to create a basic partition, if disk is "raw".
#>


$Partitions = (gwmi -Namespace 'ROOT\Cimv2' -Query "SELECT * FROM Win32_DiskDrive WHERE DeviceID Like '%PHYSICALDRIVE0'").Partitions

if($Partitions -gt 0) {
    exit 0
}

$DPCommands = @("Sel Disk 0", "Clean", "Create Par Pri", "Format FS=ntfs Quick", "Assign Letter=C")

$DPCommands | Out-File -FilePath "diskpart.txt" -Encoding ascii -Force

Start-Process -FilePath "diskpart.exe" -ArgumentList @("/S diskpart.txt") -WindowStyle Hidden -Wait -EA SilentlyContinue