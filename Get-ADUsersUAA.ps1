$Users = Import-Csv -Path 'C:\_Last Logged on User\users.csv'

ForEach ($User in $Users)
{
    Get-ADUser -Identity $User.User -Properties * | Select sAMAccountName, department, PhysicalDeliveryOfficeName | Export-csv -Path "C:\_Last Logged on User\UserData.csv" -Append
}