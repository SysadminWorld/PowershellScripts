# Script to get all user names form active directory for access into Paradigm

# Get list of users in security group
$Paradigm_Users = Get-ADGroupMember -Identity "UAA_Software_Access_Control_Paradigm_Geo"

# Write usernames into text file
$Paradigm_Users.SamAccountName | Out-File -FilePath c:\temp\Paradigm_users.txt

# Create Epos Users from text file.
& E:\Paradigm-17\Services\bin\cli\PG_epos_bulk_user_create -pns_host CAS-Licensing05 -os_users_file C:\Temp\Paradigm_users.txt