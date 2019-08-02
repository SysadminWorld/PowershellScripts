Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
$RegPath = "HKLM:\SOFTWARE\WOW6432Node\Pharos\Database Server"  
New-ItemProperty $RegPath "Port Name" -Value "2355" -Propertytype String -Force 
New-ItemProperty $RegPath "Timeout" -Value "00000078" -Propertytype DWORD -Force 
New-ItemProperty $RegPath "Host Address" -Value "$env:computername" -Propertytype String -Force