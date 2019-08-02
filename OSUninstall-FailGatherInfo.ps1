#This will gather the User Accounts that caused OSUninstall to fail, write to OSUninstall Log and Populate TS Variable.


try
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
		    $Component = "OSUninstall",
 
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
    }

$LogPath = $tsenv.Value('_SMSTSLogPath')
$LogFile = "$LogPath\OSUninstall.log"
$ScriptName = $MyInvocation.MyCommand.Name
CMTraceLog -Message  "---Start $ScriptName---" -Type 2 -LogFile $LogFile
$CurrentBuild = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 'ReleaseId' -ErrorAction SilentlyContinue
$RegistryPath = "HKLM:\$($tsenv.Value('RegistryPathOnline'))"
$RegistryPathFull = "$RegistryPath\$CurrentBuild"


$Lines = Get-Content C:\windows\logs\Dism\dism.log
$NewAccounts = Foreach($line in $Lines) {
    $SecondHalf = $null
    $FirstHalf,$SecondHalf = $line -split 'not found in rollback info.',2
    if(-not [string]::IsNullOrEmpty($SecondHalf)){
        $PartWithUserName,$null = $FirstHalf -split '[(]',2
        $SplitPartWithUserName = $PartWithUserName.Split(" ")
        #$SplitPartWithUserName[$SplitPartWithUserName.Count - 1]
        $SplitUserDomain = $SplitPartWithUserName.split("\")
        $SplitUserDomain[$SplitUserDomain.Count -1]
    }
}

$NewAccounts = $NewAccounts | select -Unique
$tsenv.Value("NewAccounts") = $NewAccounts

#Record App Issue True / False
New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_Accounts" -PropertyType String -Value $NewAccounts -Force
CMTraceLog -Message  "There are $($NewAccounts.count) Accounts that have been created since upgraded to $CurrentBuild" -Type 2 -LogFile $LogFile
CMTraceLog -Message  "Please Delete $NewAccounts and try OS Uninstall Process Again" -Type 2 -LogFile $LogFile
CMTraceLog -Message  "---End $ScriptName---" -Type 2 -LogFile $LogFile