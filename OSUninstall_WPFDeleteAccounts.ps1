<#
Created for OSUninstall which runs when DISM failed because new profiles were created since upgrade.
This launches SIMPLE WPF Form showing the new profiles that need to be deleted
gives option to click Delete which sets TS Var to "True"
or option to cancel, which sets TS Var to "False"

#>


#Check if running in TS
try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    #$tsenv.CloseProgressDialog()
}
catch
{
	Write-Verbose "Not running in a task sequence."
}

if ($tsenv -ne $null) {
    $TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
    $TSProgressUI.CloseProgressDialog()
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

$ScriptName = $MyInvocation.MyCommand.Name
$LogPath = $tsenv.Value('_SMSTSLogPath')
$LogFile = "$LogPath\OSUninstall.log"
$CurrentBuild = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 'ReleaseId' -ErrorAction SilentlyContinue
#Make sure you set the RegistryPath var in your TS!
$RegistryPath = "HKLM:\$($tsenv.Value('RegistryPath'))"
$RegistryPathFull = "$RegistryPath\$CurrentBuild"

#Load DISM LOGS & Get UserNames that Prevented OS Uninstall
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

#ERASE ALL THIS AND PUT XAML BELOW between the @" "@ - XAML Code Generated from Vistual Studio Community Ed.
$inputXML = @"
<Window x:Class="WpfApp2.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp2"
        mc:Ignorable="d"
        Title="OS Uninstall: User Intervention Required" Height="362.697" Width="561.905">
    <Grid Background="#FF007ACC">
        <Label x:Name="LabelInfo" Content="The OS Uninstall Failed because new user account profile(s) &#xA;were found that were created after the upgrade.&#xA;&#xA;If you would like the profile(s) deleted, please click Delete, this will &#xD;&#xA;reboot the machine and delete the account profile(s) and retry the Revert&#xA;&#xA;If you're unsure, or do not want to delete them, click Cancel &#xD;&#xA;and contact your support.  &#xA;&#xA;The following account profile(s) need to be removed." HorizontalAlignment="Left" Height="213" Margin="36,10,0,0" VerticalAlignment="Top" Width="499" FontSize="14" Foreground="White"/>
        <Button x:Name="ButtonDelete" Content="Delete" HorizontalAlignment="Left" Margin="347,292,0,0" VerticalAlignment="Top" Width="75" Foreground="White" Background="#FF017ACC" BorderBrush="White"/>
        <Button x:Name="ButtonCancel" Content="Cancel" HorizontalAlignment="Left" Margin="441,292,0,0" VerticalAlignment="Top" Width="75" Foreground="White" Background="#FF017ACC" BorderBrush="White"/>
        <Label x:Name="LabelProfiles" Content="&#xD;&#xA;Users: PlaceHolder" HorizontalAlignment="Left" Margin="36,223,0,0" VerticalAlignment="Top" Height="52" Width="333" Foreground="White"/>

    </Grid>
</Window>

"@       
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged properties (PowerShell cannot process them)"
    throw}
 
#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
  
$xaml.SelectNodes("//*[@Name]") | %{"trying item $($_.Name)";
    try {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
    }
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 

#===========================================================================
# Actually make the objects work
#===========================================================================

CMTraceLog -Message  "---Start $ScriptName---" -Type 2 -LogFile $LogFile

#This is what displays the Profiles that were added and need to be deleted
$WPFLabelProfiles.Content = "Profile(s): $NewAccounts"
$WPFLabelProfiles.Foreground = "Yellow"

#The Button, all the magic happens (Info written to Registry)
$WPFButtonDelete.Add_Click({

#Create RegKey Space
if ( -not ( test-path $RegistryPathFull ) ) {new-item -ItemType directory -path $RegistryPathFull -force -erroraction SilentlyContinue | out-null}

#Record App Issue True / False & Create TS Variable for TS to know to Delete Accounts
New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_AccountsDeleted" -PropertyType String -Value "True" -Force
CMTraceLog -Message  "Setting RegKey OSUninstall_AccountsDeleted to True" -Type 1 -LogFile $LogFile
$tsenv.Value('OSUninstall_AccountsDeleted') = "True"


start-sleep -Milliseconds 840
CMTraceLog -Message  "---End $ScriptName---" -Type 2 -LogFile $LogFile
$form.Close()
})

$WPFButtonCancel.Add_Click({
Exit 1
start-sleep -Milliseconds 840
CMTraceLog -Message  "---End $ScriptName---" -Type 2 -LogFile $LogFile
$form.Close()
})



#===========================================================================
# Shows the form
#===========================================================================
write-host "To show the form, run the following" -ForegroundColor Cyan
$Form.ShowDialog() | out-null

