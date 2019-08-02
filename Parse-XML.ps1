# Script to parse XML for Applications

# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

[xml]$SourceXML = Get-Content -Path $ScriptPathParent\'Mobile Device Applications.xml'

$SourceXML.mobile_device_applications.mobile_device_application | Select Name | export-csv -path $ScriptPathParent\MobileDeviceApplications.csv