<#
# This script:
#      Creates collections for OSD and Windows 10 Servicing,
#      also creates membership queries and uses include and exclude rules.
#      Check the variables (and adjust if necessary) before running
# 
# Niall Brady 2017/11/07
#> 

Function Get-CmConsolePath {
        $location = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\SMS\Setup" | 
            Select-Object -ExpandProperty "UI Installation Directory"
        $Cmconsolepath = "$location\bin\ConfigurationManager.psd1"
        if (Test-Path $Cmconsolepath) {
            return $Cmconsolepath
        }
    }
Function Create-Collection($CollectionName)
# Creates a collection with an associated Limiting collection
# 
# The rules for deciding what the limiting collection is are below:
# 
# limits OSD* collections to OSD Limiting *except for the OSD Limiting collection which is limited to All Systems*
# limits All Windows 10 collection to OSD Limiting
# limits All Windows 10* collections to All Windows 10
# limits SUM* collections to All Windows 10
# limits All Workstations and All Servers to All Systems
# 

{           
if ($CollectionName -eq $Collection_1 -or $CollectionName -eq $Collection_2 -or $CollectionName -eq $Collection_3)
             {
             write-host " (Limited to 'All Systems'). " -NoNewline
             $LimitingCollectionName = "All Systems"
             } 
             elseif ($CollectionName -eq $Collection_4 -or $CollectionName -eq $Collection_5 -or $CollectionName -eq $Collection_6 -or $CollectionName -eq $Collection_7) 
             {
             write-host " (Limited to '$LimitingCollection'). " -NoNewline
             $LimitingCollectionName = "$LimitingCollection"
             } 
             elseif ($CollectionName -eq $Collection_22) 
             {
             write-host " (Limited to '$RequiredDeploymentLimitingCollection'). " -NoNewline
             $LimitingCollectionName = "$RequiredDeploymentLimitingCollection"
             } 
             # otherwise Limit to All Windows 10
             else
             {
             write-host " (Limited to $Collection_7'). " -NoNewline
             $LimitingCollectionName = "$Collection_7"
             }  

 New-CMDeviceCollection -Name "$CollectionName" -LimitingCollectionName "$LimitingCollectionName" -RefreshType Both           
}

Function Create-Collections
{
Write-Host "Checking if collections exist, if not, create them." -ForegroundColor Green
# create an array of Collection Names
    $strCollections = @("$Collection_1", "$Collection_2", "$Collection_3", "$Collection_4", "$Collection_5", "$Collection_6", "$Collection_7", "$Collection_8", "$Collection_9", "$Collection_10", "$Collection_11", "$Collection_12", "$Collection_13", "$Collection_14", "$Collection_15", "$Collection_16", "$Collection_17", "$Collection_18", "$Collection_19", "$Collection_20", "$Collection_21", "$Collection_22")
        foreach ($CollectionName in $strCollections) {
            if (Get-CMDeviceCollection -Name $CollectionName){
                write-host "The collection '$CollectionName' already exists, skipping."
                } 
             else 
                {
                write-host "Creating collection: '$CollectionName'. " -NoNewline
                Create-Collection($CollectionName) | Out-Null
		        Write-Host "Done!" -ForegroundColor Green
                }
 }
}

Function Add-Membership-Query($TargetCollection)
{
Write-Host "Adding membership query to '$TargetCollection'." -ForegroundColor Green
Write-host "...checking for existing query which matches '$RuleName'. " -NoNewline
$check_RuleName = Get-CMDeviceCollectionQueryMembershipRule -CollectionName "$TargetCollection" -RuleName $RuleName | select-string -pattern "RuleName"
Write-Host "Done!" -ForegroundColor Green 
If ($check_RuleName -eq $NULL)
    {  
# add the query if the result was null!
    Write-host "...adding the new query. " -NoNewline
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$TargetCollection" -QueryExpression "$RuleNameQuery" -RuleName "$RuleName"
    Write-Host "Done!" -ForegroundColor Green 
}
ELSE
    {
     Write-output "...that query already exists, will not add it again."
    }
}

Function IncludeCollection($IncludeCollectionName,$check_IncludeRule,$TargetCollection) {
Write-Host "Adding Include Rule for '$TargetCollection'." -ForegroundColor Green
Write-Host "...checking for Include Collection query for '$IncludeCollectionName'. " -NoNewline 
Write-Host "Done!" -ForegroundColor Green 
IF ($check_IncludeRule -eq $NULL)
    {  
# add the query if the result was null!
    Write-host "...adding the new query. " -NoNewline
    Add-CMDeviceCollectionIncludeMembershipRule -CollectionName $TargetCollection -IncludeCollectionName "$IncludeCollectionName"
    Write-Host "Done!" -ForegroundColor Green 
}
ELSE
    {
     Write-output "...that query already exists, will not add it again."
    }
}

Function ExcludeCollection ($ExcludeCollectionName,$check_ExcludeRule,$TargetCollection) {
Write-Host "Adding Exclude Rule for '$TargetCollection'." -ForegroundColor Green
Write-Host "...checking for Exclude Collection query for '$ExcludeCollectionName'. " -NoNewline 
Write-Host "Done!" -ForegroundColor Green 
IF ($check_ExcludeRule -eq $NULL)
    {  
# add the query if the result was null!
    Write-host "...adding the new query. " -NoNewline
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $TargetCollection -ExcludeCollectionName "$ExcludeCollectionName"
    Write-Host "Done!" -ForegroundColor Green 
}
ELSE
    {
     Write-output "...that query already exists, will not add it again."
    }
}


# script begins below this line
#
# define the variables used in this script
#

$Collection_1 = "All Workstations"
$Collection_2 = "All Servers"
$Collection_3 = "OSD Limiting"
$Collection_4 = "OSD Build"
$Collection_5 = "OSD Deploy"
$Collection_6 = "OSD Excluded"
$Collection_7 = "All Windows 10"
$Collection_8 = "All Windows 10 version Other"
$Collection_9 = "All Windows 10 version 1507"
$Collection_10 = "All Windows 10 version 1511"
$Collection_11 = "All Windows 10 version 1607"
$Collection_12 = "All Windows 10 version 1703"
$Collection_13 = "All Windows 10 version 1709"
$Collection_14 = "SUM Windows 10 Other"
$Collection_15 = "SUM Windows 10 version 1507"
$Collection_16 = "SUM Windows 10 version 1511"
$Collection_17 = "SUM Windows 10 version 1607"
$Collection_18 = "SUM Windows 10 version 1703"
$Collection_19 = "SUM Windows 10 version 1709"
$Collection_20 = "SUM Windows 10 SAC"
$Collection_21 = "SUM Windows 10 LTSC"
$Collection_22 = "OSD Servicing Required Deployment"
$LimitingCollection = $Collection_3
$RequiredDeploymentLimitingCollection = $Collection_12

write-host "Starting script..." -ForegroundColor Yellow
 If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] “Administrator”))

    {
        Write-Warning “You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!”
        Break
    }
#
# connect to ConfigMgr
#

$console=Get-CmConsolePath
Import-Module $console
$SiteCode=Get-PSDrive -PSProvider CMSite
write-host "Connecting to " -ForegroundColor White -NoNewline
write-host $SiteCode -ForegroundColor Green -NoNewLine
cd "$($SiteCode):"
write-host ", done." -ForegroundColor White
 
# Create collections based on the array of collections
Create-Collections
Write-host "Collections created, to add the Queries and include/exclude rules.."
pause

# add queries to our collections
# There are no queries added for OSD Deploy, OSD Required  or OSD Excluded, please add them according to your needs, manually
$TargetCollection = $Collection_1
$RuleName = "All Workstations"
$RuleNameQuery = "select SMS_R_System.ResourceId, SMS_R_System.ResourceType, SMS_R_System.Name, SMS_R_System.SMSUniqueIdentifier, SMS_R_System.ResourceDomainORWorkgroup, SMS_R_System.Client from  SMS_R_System where SMS_R_System.OperatingSystemNameandVersion like '%Workstation%'"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_2
$RuleName = "All Servers"
$RuleNameQuery = "select * from  SMS_R_System where SMS_R_System.OperatingSystemNameandVersion like '%Server%'"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_7
$RuleName = "All Windows 10"
$RuleNameQuery = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceID = SMS_R_System.ResourceId
 where (SMS_R_System.OperatingSystemNameandVersion = 
'Microsoft Windows NT Workstation 10.0'
 or SMS_R_System.OperatingSystemNameandVersion = 
'Microsoft Windows NT Workstation 10.0 (Tablet Edition)')"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_8
$RuleName = "All Windows 10 other"
$RuleNameQuery = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceID = SMS_R_System.ResourceId
 where (SMS_R_System.OperatingSystemNameandVersion = 
'Microsoft Windows NT Workstation 10.0'
 or SMS_R_System.OperatingSystemNameandVersion = 
'Microsoft Windows NT Workstation 10.0 (Tablet Edition)')
 and SMS_G_System_OPERATING_SYSTEM.BuildNumber not in ('10240','10586','14393','15063','16299')"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_9
$RuleName = "All Windows 10 version 1507"
$RuleNameQuery = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId
 where SMS_R_System.OSBranch != 2
 and (SMS_R_System.OperatingSystemNameandVersion =   
'Microsoft Windows NT Workstation 10.0'
 or SMS_R_System.OperatingSystemNameandVersion =
'Microsoft Windows NT Workstation 10.0 (Tablet Edition)')
 and SMS_G_System_OPERATING_SYSTEM.BuildNumber in ('10240')"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_10
$RuleName = "All Windows 10 version 1511"
$RuleNameQuery = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId
 where SMS_R_System.OSBranch != 2
 and (SMS_R_System.OperatingSystemNameandVersion =   
'Microsoft Windows NT Workstation 10.0'
 or SMS_R_System.OperatingSystemNameandVersion =
'Microsoft Windows NT Workstation 10.0 (Tablet Edition)')
 and SMS_G_System_OPERATING_SYSTEM.BuildNumber in ('10586')"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_11
$RuleName = "All Windows 10 version 1607"
$RuleNameQuery = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId
 where SMS_R_System.OSBranch != 2
 and (SMS_R_System.OperatingSystemNameandVersion =   
'Microsoft Windows NT Workstation 10.0'
 or SMS_R_System.OperatingSystemNameandVersion =
'Microsoft Windows NT Workstation 10.0 (Tablet Edition)')
 and SMS_G_System_OPERATING_SYSTEM.BuildNumber in ('14393')"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_12
$RuleName = "All Windows 10 version 1703"
$RuleNameQuery = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId
 where SMS_R_System.OSBranch != 2
 and (SMS_R_System.OperatingSystemNameandVersion =   
'Microsoft Windows NT Workstation 10.0'
 or SMS_R_System.OperatingSystemNameandVersion =
'Microsoft Windows NT Workstation 10.0 (Tablet Edition)')
 and SMS_G_System_OPERATING_SYSTEM.BuildNumber in ('15063')"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_13
$RuleName = "All Windows 10 version 1709"
$RuleNameQuery = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId
 where SMS_R_System.OSBranch != 2
 and (SMS_R_System.OperatingSystemNameandVersion =   
'Microsoft Windows NT Workstation 10.0'
 or SMS_R_System.OperatingSystemNameandVersion =
'Microsoft Windows NT Workstation 10.0 (Tablet Edition)')
 and SMS_G_System_OPERATING_SYSTEM.BuildNumber in ('16299')"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_3
$RuleName = "OSD Limiting"
$RuleNameQuery = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.OperatingSystemNameandVersion like '%Workstation%' or SMS_R_System.AgentName = 'Manual Machine Entry'"
Add-Membership-Query($TargetCollection)

$TargetCollection = $Collection_4
$RuleName = "OSD Build"
$RuleNameQuery = "select *  from  SMS_R_System where SMS_R_System.AgentName = 'Manual Machine Entry'"
Add-Membership-Query($TargetCollection)

# add some include rules 

# this is for the OSD Limiting collection
$TargetCollection = $Collection_3
$IncludeCollectionName = "All Unknown Computers"
$check_IncludeRule = Get-CMDeviceCollectionIncludeMembershipRule -CollectionName "$TargetCollection" -IncludeCollectionName "$IncludeCollectionName" | select-string -pattern "RuleName"
IncludeCollection $IncludeCollectionName $check_IncludeRule $TargetCollection

$TargetCollection = $Collection_3
$IncludeCollectionName = $Collection_1
$check_IncludeRule = Get-CMDeviceCollectionIncludeMembershipRule -CollectionName "$TargetCollection" -IncludeCollectionName "$IncludeCollectionName" | select-string -pattern "RuleName"
IncludeCollection $IncludeCollectionName $check_IncludeRule $TargetCollection

# add some exclude rules 
$TargetCollection = $Collection_22
$ExcludeCollectionName = $Collection_6
$check_ExcludeRule = Get-CMDeviceCollectionExcludeMembershipRule -CollectionName "$TargetCollection" -ExcludeCollectionName "$ExcludeCollectionName" | select-string -pattern "RuleName"
ExcludeCollection $ExcludeCollectionName $check_ExcludeRule $TargetCollection


Write-Host "Operations completed, exiting." -ForegroundColor Green