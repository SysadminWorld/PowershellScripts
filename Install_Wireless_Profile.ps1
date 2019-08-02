# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

#Enable and then disable all the WAN Miniports and then add the provisioning package
Enable-NetAdapter -Name "WAN Miniport (IKEv2)" -Confirm:$false
Enable-NetAdapter -Name "WAN Miniport (IP)" -Confirm:$false
Enable-NetAdapter -Name "WAN Miniport (IPv6)" -Confirm:$false
Enable-NetAdapter -Name "WAN Miniport (L2TP)" -Confirm:$false
Enable-NetAdapter -Name "WAN Miniport (Network Monitor)" -Confirm:$false
Enable-NetAdapter -Name "WAN Miniport (PPPOE)" -Confirm:$false
Enable-NetAdapter -Name "WAN Miniport (PPTP)" -Confirm:$false
Enable-NetAdapter -Name "WAN Miniport (SSTP)" -Confirm:$false

Disable-NetAdapter -Name "WAN Miniport (IKEv2)" -Confirm:$false
Disable-NetAdapter -Name "WAN Miniport (IP)" -Confirm:$false
Disable-NetAdapter -Name "WAN Miniport (IPv6)" -Confirm:$false
Disable-NetAdapter -Name "WAN Miniport (L2TP)" -Confirm:$false
Disable-NetAdapter -Name "WAN Miniport (Network Monitor)" -Confirm:$false
Disable-NetAdapter -Name "WAN Miniport (PPPOE)" -Confirm:$false
Disable-NetAdapter -Name "WAN Miniport (PPTP)" -Confirm:$false
Disable-NetAdapter -Name "WAN Miniport (SSTP)" -Confirm:$false

#Import Wireless Server Cert
Import-Certificate -FilePath $ScriptPathParent\anc-ne-ise.apps.ad.alaska.edu.p7b -CertStoreLocation cert:\LocalMachine\root

#Import Wireless profile
netsh wlan add profile filename="$ScriptPathParent\Wi-Fi-UAA Wifi - Anchorage.xml"