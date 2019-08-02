# Regex pattern for SIDs
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
 
# Get Username, SID, and location of ntuser.dat for all users
$ProfileList = gp 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} | 
    Select  @{name="SID";expression={$_.PSChildName}}, 
            @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
            @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}
 
# Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
$LoadedHives = gci Registry::HKEY_USERS | ? {$_.PSChildname -match $PatternSID} | Select @{name="SID";expression={$_.PSChildName}}
 
# Get all users that are not currently logged
$UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select @{name="SID";expression={$_.InputObject}}, UserHive, Username

$Key1 = 'SOFTWARE\Leica Geosystems\LGO\Combined\Settings\Lfx\CPPViewLicensesSettings::CLfxEditString::9728'
$Key2 = 'SOFTWARE\Leica Geosystems\LGO\Combined\Settings\SkiProAux\License Manager'
$Key3 = 'SOFTWARE\Leica Geosystems\LGO\Combined\Settings\Lfx\CPPViewLicenses::CLfxEditString::9730'
$Key4 = 'SOFTWARE\FLEXlm License Manager'

# Loop through each profile on the machine
Foreach ($item in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    IF ($item.SID -in $UnloadedHives.SID) {
        reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
    }
 
    #####################################################################
    # This is where you can read/modify a users portion of the registry 
    #$SID = $($item.SID)

    $Key10 = "registry::HKEY_USERS\$($Item.SID)\$Key1"
    $Key20 = "registry::HKEY_USERS\$($Item.SID)\$Key2"
    $Key30 = "registry::HKEY_USERS\$($Item.SID)\$Key3"
    $Key40 = "registry::HKEY_USERS\$($Item.SID)\$Key4"

    # This example lists the Uninstall keys for each user registry hive
    "{0}" -f $($item.Username) | Write-Output

    New-Item -Path $Key10 -Force | Out-Null
    New-ItemProperty -Path $Key10 -Name "Doc_1" -Value "anc-datem-lic.ua.ad.alaska.edu;" -PropertyType STRING -Force | Out-Null
    New-Item -Path $Key20 -Force | Out-Null
    New-ItemProperty -Path $Key20 -Name "License Server" -Value "@anc-datem-lic.ua.ad.alaska.edu;" -PropertyType STRING -Force | Out-Null
    New-Item -Path $Key30 -Force | Out-Null
    New-ItemProperty -Path $Key30 -Name "Doc_1" -Value "00102-43114-00018-61243-19FD9;" -PropertyType STRING -Force | Out-Null
    New-Item -Path $Key40 -Force | Out-Null
    New-ItemProperty -Path $Key40 -Name "LGS_LICENSE_FILE" -Value "@anc-datem-lic.ua.ad.alaska.edu;" -PropertyType STRING -Force | Out-Null
    
    #####################################################################
 
    # Unload ntuser.dat        
    IF ($item.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($Item.SID) | Out-Null
    }
}
