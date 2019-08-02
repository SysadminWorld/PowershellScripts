# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Adds the Enrolment Services Provisioning Package
Install-ProvisioningPackage -Path $ScriptPathParent\Enrollment_Services_Kiosk_Setup.ppkg -ForceInstall -QuietInstall


