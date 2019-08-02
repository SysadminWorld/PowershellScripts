$Printers = Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers
$InstalledPrinter = @()
Foreach ($Printer in $Printers)
{
    If (($Printer.PSChildName -notlike 'Send To*') -and ($Printer.PSChildName -notlike 'Microsoft*') -and ($Printer.PSChildName -notlike 'fax') -and ($Printer.PSChildName -notlike '*PDF*') -and ($Printer.PSChildName -notlike 'Webex*')){
        $InstalledPrinter += $Printer.PSChildName
    }
}
Write-Host $InstalledPrinter