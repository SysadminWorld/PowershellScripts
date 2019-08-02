<#	
  .NOTES
  ===========================================================================
   Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.140
   Created on:   	05/10/2017 13:07
   Created by:   	Terence Beggs
   Organization: 	SCConfigMgr 
   Filename:     	MicrosoftTeams-OSD-Successful-v0.4.ps1

  ===========================================================================
  .DESCRIPTION
    This script uses Microsoft Teams to notify when a OSD task sequence has completed successfully.

  .SOCIAL
   	Twitter : @terencebeggs
    Blog : http://www.scconfigmgr.com	
    Link to original post: http://www.scconfigmgr.com/2017/10/06/configmgr-osd-notification-service-teams/
#>

$uri = 'https://outlook.office.com/webhook/81a158d3-ff2c-42fc-82fc-d002fb8fbdb2@5a6dc059-5067-416e-af81-4b579d900323/IncomingWebhook/66c3899e4b044c1dae9dcf84daded4ad/abbc8f24-e670-4f0d-9066-0786ada3da93'

# Date and Time
$DateTime = Get-Date -Format g #Time

# Time
$Time = get-date -format HH:mm

# Computer Make
$Make = (Get-WmiObject -Class Win32_BIOS).Manufacturer

# Computer Model
$Model = (Get-WmiObject -Class Win32_ComputerSystem).Model

# Computer Name
$Name = (Get-WmiObject -Class Win32_ComputerSystem).Name

# Computer Serial Number
[string]$SerialNumber = (Get-WmiObject win32_bios).SerialNumber

# IP Address of the Computer
$IPAddress = (Get-WmiObject win32_Networkadapterconfiguration | Where-Object{ $_.ipaddress -notlike $null }).IPaddress | Select-Object -First 1

# Uses TS Env doesnt give much on x64 arch
#$TSsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue
#$TSlogPath = $tsenv.Value("_SMSTSLogPath")

# these values would be retrieved from or set by an application

$body = ConvertTo-Json -Depth 4 @{
  title    = "$Name Completed Successfully"
  text	 = "  "
  sections = @(
    @{
      activityTitle    = '<h1 style=color:red;>Upgrade Failed'
      activitySubtitle = 'Windows Upgrade'
      #activityText	 = '@team'
      activityImage    = 'http://uaa.alaska.edu//about/administrative-services/departments/information-technology-services/our-services/endpoint-management/_images/Failure.png' # this value would be a path to a nice image you would like to display in notifications
    },
    @{
      title = '<h2 style=color:blue;>Deployment Details'
      facts = @(
        @{
          name  = 'Name'
          value = $Name
        },
        @{
          name  = 'Finished'
          value = "$DateTime"
        },
        @{
          name  = 'IP Addresss'
          value = $IPAddress
        },
        @{
          name  = 'Make'
          value = $Make
        },
        @{
          name  = 'Model'
          value = $Model
        },
        @{
          name  = 'Serial'
          value = $SerialNumber
        }
      )
    }
  )
}

Invoke-RestMethod -uri $uri -Method Post -body $body -ContentType 'application/json'