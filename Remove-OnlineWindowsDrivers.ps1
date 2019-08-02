# Gets all drivers from online image
$drivers = Get-WindowsDriver -Online -All

# View All drivers where the manufacturer is not Microsoft and it is a Display Driver
$DisplayDrivers = $drivers | Where-Object {($_.ClassName -eq 'Display' -and $_.ProviderName -notlike 'Microsoft*')}

# Attempt to remove display driver
ForEach ($Driver in $DisplayDrivers) 
    {
        & pnputil /delete-driver $Driver.driver /force
    }