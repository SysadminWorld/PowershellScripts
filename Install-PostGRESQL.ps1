# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Install PostgreSQL
& $ScriptPathParent\postgresql-9.6.3-3-windows-x64.exe --unattendedmodeui none --mode unattended --superpassword admin --servicepassword admin --disable-stackbuilder yes | Out-Null

#Install pgAgent
& $ScriptPathParent\edb_pgagent.exe --unattendedmodeui none --mode unattended --pgpassword admin --systempassword admin | Out-Null

#Install pgJDBC
& $ScriptPathParent\edb_pgjdbc.exe --unattendedmodeui none --mode unattended | Out-Null

#Install PostgreSQL
& $ScriptPathParent\postgresql_96.exe --unattendedmodeui none --mode unattended --superpassword admin --servicepassword admin --disable-stackbuilder yes | Out-Null

#Install Postgis
& $ScriptPathParent\ppostgis_2_4_pg96.exe /S | Out-Null
