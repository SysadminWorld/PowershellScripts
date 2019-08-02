#Add-OdbcDsn -Name "CPTest" -DriverName "SQL Server" -DsnType "System" -SetPropertyValue @("Server=137.229.141.149\\sqlexpress", "Trusted_Connection=Yes", "Database=CPTest")

Add-OdbcDsn -DriverName "SQL Server" -DsnType System -Name uaa-cp -Platform 32-bit -SetPropertyValue @("Server=qdfm0qeswe.database.windows.net", "Trusted_Connection=Yes", "Database=uaa-cp")
Add-OdbcDsn -DriverName "SQL Server" -DsnType System -Name CPTest -Platform 32-bit -SetPropertyValue @("Server=137.229.141.149\\sqlexpress", "Trusted_Connection=Yes", "Database=CPTest")