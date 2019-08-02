<# 
.SYNOPSIS 
Use Delprof2.exe to delete profiles that prvented OS Uninstall
tool from here: https://helgeklein.com/free-tools/delprof2-user-profile-deletion-tool
Permission was granted for Garytown.com to redistribute in content
.DESCRIPTION 
Gets Top Console user from ConfigMgr Client WMI, then runs delprof tool, excluding top console user list, 
and deletes any other inactive accounts based on how many days that you set in the -Days parameter.  
typical arugments;
        l   List only, do not delete (what-if mode) - Set by default
        u   Unattended (no confirmation) - Recommended to leave logs
        q   Quiet (no output and no confirmation)

.LINK
https://garytown.com
https://helgeklein.com/free-tools/delprof2-user-profile-deletion-tool - to see what arugments are available.


Notes are in the script.. but basically this gets list of profiles that blocked OS Unisntall from Dism and deletes them.
This was meant to be used in a TS where this script only runs if user approved deleting the profiles.
#> try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    #$tsenv.CloseProgressDialog()
}
catch
{
	Write-Verbose "Not running in a task sequence."
}
#region: CMTraceLog Function formats logging in CMTrace style
        function CMTraceLog {
         [CmdletBinding()]
    Param (
		    [Parameter(Mandatory=$false)]
		    $Message,
 
		    [Parameter(Mandatory=$false)]
		    $ErrorMessage,
 
		    [Parameter(Mandatory=$false)]
		    $Component = "OSUninstall-ProfileCleanUp",
 
		    [Parameter(Mandatory=$false)]
		    [int]$Type,
		
		    [Parameter(Mandatory=$true)]
		    $LogFile
	    )
    <#
    Type: 1 = Normal, 2 = Warning (yellow), 3 = Error (red)
    #>
	    $Time = Get-Date -Format "HH:mm:ss.ffffff"
	    $Date = Get-Date -Format "MM-dd-yyyy"
 
	    if ($ErrorMessage -ne $null) {$Type = 3}
	    if ($Component -eq $null) {$Component = " "}
	    if ($Type -eq $null) {$Type = 1}
 
	    $LogMessage = "<![LOG[$Message $ErrorMessage" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Type`" thread=`"`" file=`"`">"
	    $LogMessage | Out-File -Append -Encoding UTF8 -FilePath $LogFile
    }$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$ScriptName = $MyInvocation.MyCommand.Name
if ($tsenv){$LogPath = $tsenv.Value('_SMSTSLogPath')}
else {$LogPath = "C:\Windows\CCM\Logs"}
$LogFile = "$LogPath\OSUninstall.log"
$DelProf2Log = "$LogPath\DelProf2.log"

CMTraceLog -Message  "---Start $ScriptName---" -Type 2 -LogFile $LogFile

#Load DISM LOGS & Get UserNames that Prevented OS Uninstall
$Lines = Get-Content C:\windows\logs\Dism\dism.log
Foreach($line in $Lines) {
    $SecondHalf = $null
    $FirstHalf,$SecondHalf = $line -split 'not found in rollback info.',2
    if(-not [string]::IsNullOrEmpty($SecondHalf)){
        $PartWithUserName,$null = $FirstHalf -split '[(]',2
        $SplitPartWithUserName = $PartWithUserName.Split(" ")
        
        #This is the Username with Domain (VIAMONSTRA\garytown)
        $DomainProfileName = $SplitPartWithUserName[$SplitPartWithUserName.Count - 1]
        $SplitUserDomain = $SplitPartWithUserName.split("\")
        
        #This is the username with no domain (garytown)
        $DeleteProfile = $SplitUserDomain[$SplitUserDomain.Count -1]
        
        #Log & Delete Each Offending Profile
        CMTraceLog -Message  "Running Command: $ScriptDir\DelProf2.exe /id:$($DeleteProfile) /u" -Type 1 -LogFile $LogFile
        $DelProfOutput = [string] (& $ScriptDir\DelProf2.exe /id:$DeleteProfile /u 2>&1)
        CMTraceLog -Message  "$DelProfOutput" -Type 1 -LogFile $DelProf2Log
    
    #Get Local Profiles to be used for confirmation if Profile was actually deleted.
    $localProfiles = Get-CimInstance -ClassName Win32_UserProfile -Filter Special=FALSE -PipelineVariable user |
        ForEach-Object -Begin {$ErrorActionPreference = 'Stop'} {
            try
            {
                $id = [System.Security.Principal.SecurityIdentifier]::new($user.SID)
                $id.Translate([System.Security.Principal.NTAccount]).Value
            }
            catch
            {
                Write-Warning -Message "Failed to translate $($user.SID)! $PSItem"
            }
        }
    #Check if the list of Local Profiles Contain the Profile you think you just deleted
    if ($localProfiles -icontains $DomainProfileName)
        {
        #If it finds the profile still, report that information & set Var to Failed
        CMTraceLog -Message  "Failed to Delete $($DomainProfileName)" -Type 1 -LogFile $LogFile
        Write-Output "Failed to Delete $DomainProfileName"
        if ($tsenv){$tsenv.Value('OSUninstall-ProfileCleanup') = "Failed"}
        }
    Else
        {
        #Log if it does NOT find it, aka it deleted the profile successfully!!
        CMTraceLog -Message  "Successfully Deleted: $($DomainProfileName)" -Type 1 -LogFile $LogFile
        Write-Output "Successfully Deleted: $DomainProfileName"
        }
    }
}

CMTraceLog -Message  "---End $ScriptName---" -Type 2 -LogFile $LogFile