#Created for OSUninstall "Front End" to get user feedback as to why we are rolling back.


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

#Get Current User Account Name
$regexa = '.+Domain="(.+)",Name="(.+)"$' 
$regexd = '.+LogonId="(\d+)"$' 
$logon_sessions = @(gwmi win32_logonsession -ComputerName $env:COMPUTERNAME) 
$logon_users = @(gwmi win32_loggedonuser -ComputerName $env:COMPUTERNAME) 
$session_user = @{} 
$logon_users |% { $_.antecedent -match $regexa > $nul ;$username = $matches[2] ;$_.dependent -match $regexd > $nul ;$session = $matches[1] ;$session_user[$session] += $username } 
$currentUser = $logon_sessions |%{ 
    $loggedonuser = New-Object -TypeName psobject 
    $loggedonuser | Add-Member -MemberType NoteProperty -Name "User" -Value $session_user[$_.logonid] 
    $loggedonuser | Add-Member -MemberType NoteProperty -Name "Type" -Value $_.logontype
    $loggedonuser | Add-Member -MemberType NoteProperty -Name "Auth" -Value $_.authenticationpackage 
    ($loggedonuser  | where {$_.Type -eq "2" -and $_.Auth -eq "Kerberos"}).User 
    } 
$currentUser = $currentUser | select -Unique

$CurrentBuild = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 'ReleaseId' -ErrorAction SilentlyContinue
#Make sure you set the RegistryPath var in your TS!
$RegistryPath = "HKLM:\$($tsenv.Value('RegistryPath'))"
$RegistryPathFull = "$RegistryPath\$CurrentBuild"
$ScriptName = $MyInvocation.MyCommand.Name
$LogPath = $tsenv.Value('_SMSTSLogPath')
$LogFile = "$LogPath\OSUninstall.log"

Function Get-Software  {

  [OutputType('System.Software.Inventory')]
  [Cmdletbinding()] 
  Param( 
  [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)] 
  [String[]]$Computername=$env:COMPUTERNAME
  )         
  Begin {
  }
  Process  {     
  ForEach  ($Computer in  $Computername){ 
  If  (Test-Connection -ComputerName  $Computer -Count  1 -Quiet) {
  $Paths  = @("SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall","SOFTWARE\\Wow6432node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")         
  ForEach($Path in $Paths) { 
  Write-Verbose  "Checking Path: $Path"
  #  Create an instance of the Registry Object and open the HKLM base key 
  Try  { 
  $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$Computer,'Registry64') 
  } Catch  { 
  Write-Error $_ 
  Continue 
  } 
  #  Drill down into the Uninstall key using the OpenSubKey Method 
  Try  {
  $regkey=$reg.OpenSubKey($Path)  
  # Retrieve an array of string that contain all the subkey names 
  $subkeys=$regkey.GetSubKeyNames()      
  # Open each Subkey and use GetValue Method to return the required  values for each 
  ForEach ($key in $subkeys){   
  Write-Verbose "Key: $Key"
  $thisKey=$Path+"\\"+$key 
  Try {  
  $thisSubKey=$reg.OpenSubKey($thisKey)   
  # Prevent Objects with empty DisplayName 
  $DisplayName =  $thisSubKey.getValue("DisplayName")
  If ($DisplayName  -AND $DisplayName  -notmatch '^Update  for|rollup|^Security Update|^Service Pack|^HotFix') {
  $Date = $thisSubKey.GetValue('InstallDate')
  If ($Date) {
  Try {
  $Date = [datetime]::ParseExact($Date, 'yyyyMMdd', $Null)
  } Catch{
  Write-Warning "$($Computer): $_ <$($Date)>"
  $Date = $Null
  }
  } 
  # Create New Object with empty Properties 
  $Publisher =  Try {
  $thisSubKey.GetValue('Publisher').Trim()
  } 
  Catch {
  $thisSubKey.GetValue('Publisher')
  }
  $Version = Try {
  #Some weirdness with trailing [char]0 on some strings
  $thisSubKey.GetValue('DisplayVersion').TrimEnd(([char[]](32,0)))
  } 
  Catch {
  $thisSubKey.GetValue('DisplayVersion')
  }
  $UninstallString =  Try {
  $thisSubKey.GetValue('UninstallString').Trim()
  } 
  Catch {
  $thisSubKey.GetValue('UninstallString')
  }
  $InstallLocation =  Try {
  $thisSubKey.GetValue('InstallLocation').Trim()
  } 
  Catch {
  $thisSubKey.GetValue('InstallLocation')
  }
  $InstallSource =  Try {
  $thisSubKey.GetValue('InstallSource').Trim()
  } 
  Catch {
  $thisSubKey.GetValue('InstallSource')
  }
  $HelpLink = Try {
  $thisSubKey.GetValue('HelpLink').Trim()
  } 
  Catch {
  $thisSubKey.GetValue('HelpLink')
  }
  $Object = [pscustomobject]@{
  Computername = $Computer
  DisplayName = $DisplayName
  Version  = $Version
  InstallDate = $Date
  Publisher = $Publisher
  UninstallString = $UninstallString
  InstallLocation = $InstallLocation
  InstallSource  = $InstallSource
  HelpLink = $thisSubKey.GetValue('HelpLink')
  EstimatedSizeMB = [decimal]([math]::Round(($thisSubKey.GetValue('EstimatedSize')*1024)/1MB,2))
  }
  $Object.pstypenames.insert(0,'System.Software.Inventory')
  Write-Output $Object
  }
  } Catch {
  Write-Warning "$Key : $_"
  }   
  }
    } Catch  {}   
  $reg.Close() 
  }                  
  } Else  {
  Write-Error  "$($Computer): unable to reach remote system!"
  }
  } 
  } 
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


$AppNames = (Get-Software).DisplayName |Sort-Object


$CurrentBuild = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" 'ReleaseId' -ErrorAction SilentlyContinue
$IPULastRun = Get-ItemPropertyValue $RegistryPathFull "IPULastRun"
$CurrentDate = Get-Date -f 's'
$DaysSinceUpgrade = ([datetime]$CurrentDate) - ([datetime]$IPULastRun) $DaysSinceUpgrade = [math]::Round($DifferenceSetup.TotalDays)
$OSUninstallWindow = DISM.EXE /Online /Get-OSUninstallWindow$OSUninstallWindow = $OSUninstallWindow | Select-String -Pattern "Uninstall Window"$OSUninstallWindow = $OSUninstallWindow.ToString()$OSUninstallWindow = $OSUninstallWindow.Substring($OSUninstallWindow.Length - 2)$OSUninstallWindow = $OSUninstallWindow.Trim()$DaysLeftforOSUNinstall = $OSUninstallWindow - $DaysSinceUpgrade
Write-Host $OSUninstallWindow
#Replaced in the script were this is used with TS Variable SMSTS_PreviousOSBuild
#$PreviousOSBuild = Get-ItemPropertyValue "HKLM:\$($tsenv.Value('RegistryPath'))" 'LastOSUpgradeFrom'
#$PreviousOSBuild = "1709"


#ERASE ALL THIS AND PUT XAML BELOW between the @" "@ - XAML Code Generated from Vistual Studio Community Ed.
$inputXML = @"
<Window x:Class="OSUninstall.MainWindow"

        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:OSUninstall"
        mc:Ignorable="d"
        Title="Go back to earlier build" Height="496.106" Width="762.193">

    <Grid Margin="0,0,2,-3" Background="#FF007ACC">
        <Label x:Name="WhyGoBack" Content="Why are you going back?" HorizontalAlignment="Left" Height="50" Margin="40,36,0,0" VerticalAlignment="Top" Width="413" FontSize="20" Foreground="White"/>
        <CheckBox x:Name="OSUninstall_AppIssue" Content="My apps don't work on this version" HorizontalAlignment="Left" Margin="56,79,0,0" VerticalAlignment="Top" Foreground="White"/>
        <CheckBox x:Name="OSUninstall_DeviceIssue" Content="My devices don't work on this version" HorizontalAlignment="Left" Margin="56,151,0,0" VerticalAlignment="Top" Foreground="White"/>
        <CheckBox x:Name="OSUninstall_EarlierBuild" Content="Earlier version seemed more reliable (i.e. Blue Screen issues)" HorizontalAlignment="Left" Margin="56,228,0,0" VerticalAlignment="Top" Foreground="White"/>
        <CheckBox x:Name="OSUninstall_AnotherReason" Content="For another reason (specify below)" HorizontalAlignment="Left" Margin="56,260,0,0" VerticalAlignment="Top" Foreground="White"/>
        <Label x:Name="TellMeMore" Content="Tell us more:" HorizontalAlignment="Left" Margin="56,282,0,0" VerticalAlignment="Top" RenderTransformOrigin="-0.34,0.38" Foreground="White"/>
        <TextBox x:Name="OSUninstall_TellUsMore" HorizontalAlignment="Left" Height="23" Margin="75,315,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="619"/>
        <Button x:Name="ButtonNext" Content="Next" HorizontalAlignment="Left" Margin="523,417,0,0" VerticalAlignment="Top" Width="75" Foreground="White" Background="#FF007ACC" BorderBrush="White"/>
        <Button x:Name="ButtonCancel" Content="Cancel" HorizontalAlignment="Left" Margin="617,417,0,0" VerticalAlignment="Top" Width="75" Foreground="White" Background="#FF017ACC" BorderBrush="White"/>
        <Label x:Name="UserName" Content="Name:" HorizontalAlignment="Left" Margin="56,343,0,0" VerticalAlignment="Top" Width="76" Foreground="White"/>
        <TextBox x:Name="OSUninstall_ContactPerson" HorizontalAlignment="Left" Height="23" Margin="78,374,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="236"/>
        <Label Content="Can we contact you if we have follow up questions?" HorizontalAlignment="Left" Margin="326,343,0,0" VerticalAlignment="Top" Width="286" Foreground="White"/>
        <RadioButton x:Name="OSUninstall_ContactAllowedYes" Content="Yes" HorizontalAlignment="Left" Margin="408,374,0,0" VerticalAlignment="Top" Foreground="White"/>
        <RadioButton x:Name="OSUninstall_ContactAllowedNo" Content="No" HorizontalAlignment="Left" Margin="485,374,0,0" VerticalAlignment="Top" Foreground="White"/>
        <Label x:Name="IfMultiApps" Content="(If there are multiple app issues, use the Tell us more field below to list the others)" HorizontalAlignment="Left" Margin="71,94,0,0" VerticalAlignment="Top" Width="483" Foreground="White"/>
        <Label x:Name="IfMultiDevices" Content="(If there are multiple device issues, use the Tell us more field below to list the others)" HorizontalAlignment="Left" Margin="71,166,0,0" VerticalAlignment="Top" Width="483" Foreground="White"/>
        <TextBox x:Name="OSUninstall_DeviceName" HorizontalAlignment="Left" Height="23" Margin="75,192,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="619"/>
        <ComboBox x:Name="OSUninstall_AppName" HorizontalAlignment="Left" Margin="75,120,0,0" VerticalAlignment="Top" Width="617"/>
        <Label x:Name="DaysLeft" Content="Days left in OSUninstall Window:  After this, you will not be able to revert back to Windows 10 Build" HorizontalAlignment="Left" Height="56" Margin="39,10,0,0" VerticalAlignment="Top" Width="577" Foreground="White"/>
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


CMTraceLog -Message  "---Starting $ScriptName---" -Type 2 -LogFile $LogFile

$WPFDaysLeft.Content = "Days left in OS Uninstall Window: $DaysLeftforOSUNinstall  After this, you will not be able to revert back to Windows 10 $($tsenv.Value('SMSTS_PreviousOSBuild'))"
$WPFDaysLeft.Foreground = "Yellow"


#Uninstall_AppName
#On Check
$WPFOSUninstall_AppName.IsEnabled = $false
$WPFOSUninstall_AppIssue.Add_Checked({
    $WPFOSUninstall_AppName.IsEnabled = $true
    $WPFOSUninstall_AppName.ItemsSource = $AppNames
    if ($WPFOSUninstall_ContactAllowedYes.IsChecked -eq $true -or $WPFOSUninstall_ContactAllowedNo.IsChecked -eq $true){$WPFbuttonNext.IsEnabled = $true}
    })
#UnCheck
$WPFOSUninstall_AppIssue.Add_UnChecked({
    $WPFOSUninstall_AppName.IsEnabled = $false
    $WPFOSUninstall_AppName.Text = $null
    if ($WPFOSUninstall_AnotherReason.IsChecked -eq $false -and $WPFOSUninstall_EarlierBuild.IsChecked -eq $false -and $WPFOSUninstall_DeviceIssue.IsChecked -eq $false -and $WPFOSUninstall_AppIssue.IsChecked -eq $false){$WPFbuttonNext.IsEnabled = $false}
    })


#Uninstall_DeviceName
#On Check
$WPFOSUninstall_DeviceName.IsEnabled = $false
$WPFOSUninstall_DeviceIssue.Add_Checked({
    $WPFOSUninstall_DeviceName.IsEnabled = $true
    if ($WPFOSUninstall_ContactAllowedYes.IsChecked -eq $true -or $WPFOSUninstall_ContactAllowedNo.IsChecked -eq $true){$WPFbuttonNext.IsEnabled = $true}
    })
#UnCheck
$WPFOSUninstall_DeviceIssue.Add_UnChecked({
    $WPFOSUninstall_DeviceName.IsEnabled = $false
    $WPFOSUninstall_DeviceName.Text = $null
    if ($WPFOSUninstall_AnotherReason.IsChecked -eq $false -and $WPFOSUninstall_EarlierBuild.IsChecked -eq $false -and $WPFOSUninstall_DeviceIssue.IsChecked -eq $false -and $WPFOSUninstall_AppIssue.IsChecked -eq $false){$WPFbuttonNext.IsEnabled = $false}
    })


#Uninstall_EarlierBuild
#On Check
$WPFOSUninstall_EarlierBuild.Add_Checked({
    if ($WPFOSUninstall_ContactAllowedYes.IsChecked -eq $true -or $WPFOSUninstall_ContactAllowedNo.IsChecked -eq $true){$WPFbuttonNext.IsEnabled = $true}
    })
#UnCheck
$WPFOSUninstall_EarlierBuild.Add_UnChecked({
    if ($WPFOSUninstall_AnotherReason.IsChecked -eq $false -and $WPFOSUninstall_EarlierBuild.IsChecked -eq $false -and $WPFOSUninstall_DeviceIssue.IsChecked -eq $false -and $WPFOSUninstall_AppIssue.IsChecked -eq $false){$WPFbuttonNext.IsEnabled = $false}
    })

#OSUninstall_TellUsMore
#On Check
$WPFOSUninstall_TellUsMore.IsEnabled = $false
$WPFOSUninstall_AnotherReason.Add_Checked({
    $WPFOSUninstall_TellUsMore.IsEnabled = $true
    if ($WPFOSUninstall_ContactAllowedYes.IsChecked -eq $true -or $WPFOSUninstall_ContactAllowedNo.IsChecked -eq $true){$WPFbuttonNext.IsEnabled = $true}
    })
#UnCheck
$WPFOSUninstall_AnotherReason.Add_UnChecked({
    $WPFOSUninstall_TellUsMore.IsEnabled = $false
    $WPFOSUninstall_TellUsMore.Text = $null
    if ($WPFOSUninstall_AnotherReason.IsChecked -eq $false -and $WPFOSUninstall_EarlierBuild.IsChecked -eq $false -and $WPFOSUninstall_DeviceIssue.IsChecked -eq $false -and $WPFOSUninstall_AppIssue.IsChecked -eq $false){$WPFbuttonNext.IsEnabled = $false}
    })




#Enable Contact Name Field if "Yes" is choosen.  Clears Field if switches to "No"
$WPFOSUninstall_ContactPerson.IsEnabled = $false
$WPFOSUninstall_ContactAllowedYes.Add_Click({$WPFUserName.Visibility = 'Visible' })
$WPFOSUninstall_ContactAllowedYes.Add_Click({$WPFOSUninstall_ContactPerson.IsEnabled = $true })
$WPFOSUninstall_ContactAllowedYes.Add_Click({$WPFOSUninstall_ContactPerson.Text = $CurrentUser })
$WPFOSUninstall_ContactAllowedNo.Add_Click({$WPFOSUninstall_ContactPerson.IsEnabled = $false })
$WPFOSUninstall_ContactAllowedNo.Add_Click({$WPFOSUninstall_ContactPerson.Text = $null })

#Next Button Enabled
$WPFbuttonNext.IsEnabled = $false

$WPFOSUninstall_ContactAllowedYes.Add_Click(
{
 if ($WPFOSUninstall_AnotherReason.IsChecked -eq "True" -or $WPFOSUninstall_EarlierBuild.IsChecked -eq "True" -or $WPFOSUninstall_DeviceIssue.IsChecked -eq "True" -or $WPFOSUninstall_AppIssue.IsChecked -eq "True" ){$WPFbuttonNext.IsEnabled = $true }
 })

 $WPFOSUninstall_ContactAllowedNo.Add_Click(
{
 if ($WPFOSUninstall_AnotherReason.IsChecked -eq "True" -or $WPFOSUninstall_EarlierBuild.IsChecked -eq "True" -or $WPFOSUninstall_DeviceIssue.IsChecked -eq "True" -or $WPFOSUninstall_AppIssue.IsChecked -eq "True" ){$WPFbuttonNext.IsEnabled = $true }
 })

#$WPFOSUninstall_ContactAllowedYes.Add_Click({$WPFbuttonNext.IsEnabled = $true })
#$WPFOSUninstall_ContactAllowedNo.Add_Click({$WPFbuttonNext.IsEnabled = $true })



#The Button, all the magic happens (Info written to Registry)
$WPFbuttonNext.Add_Click({

#Create RegKey Space
if ( -not ( test-path $RegistryPathFull ) ) {new-item -ItemType directory -path $RegistryPathFull -force -erroraction SilentlyContinue | out-null}

#Record App Issue True / False
New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_AppIssue" -PropertyType String -Value $WPFOSUninstall_AppIssue.IsChecked -Force
CMTraceLog -Message  "Setting RegKey OSUninstall_AppIssue to $($WPFOSUninstall_AppIssue).IsChecked" -Type 1 -LogFile $LogFile

#Record Which App
if ($WPFOSUninstall_AppIssue.IsChecked -eq "True")
    {
    New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_AppName" -PropertyType String -Value $($WPFOSUninstall_AppName).Text -Force
    CMTraceLog -Message  "Setting RegKey OSUninstall_AppName to $($WPFOSUninstall_AppName.Text)" -Type 1 -LogFile $LogFile
    }

#Record Device Issue True / False
New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_DeviceIssue" -PropertyType String -Value $($WPFOSUninstall_DeviceIssue).IsChecked -Force
CMTraceLog -Message  "Setting RegKey OSUninstall_DeviceIssue to $($WPFOSUninstall_DeviceIssue).IsChecked" -Type 1 -LogFile $LogFile

#Record Which Device
if ($WPFOSUninstall_DeviceIssue.IsChecked -eq "True")
    {
    New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_DeviceName" -PropertyType String -Value $($WPFOSUninstall_DeviceName).Text -Force
    CMTraceLog -Message  "Setting RegKey OSUninstall_DeviceName to $($WPFOSUninstall_DeviceName).Text" -Type 1 -LogFile $LogFile
    }

#Record Earlier Build True / False
New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_EarlierBuild" -PropertyType String -Value $($WPFOSUninstall_EarlierBuild).IsChecked -Force
CMTraceLog -Message  "Setting RegKey OSUninstall_EarlierBuild to $($WPFOSUninstall_EarlierBuild).IsChecked" -Type 1 -LogFile $LogFile

#Record Another REason True / False
New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_AnotherReason" -PropertyType String -Value $($WPFOSUninstall_AnotherReason).IsChecked -Force
CMTraceLog -Message  "Setting RegKey OSUninstall_AnotherReason to $($WPFOSUninstall_AnotherReason).IsChecked" -Type 1 -LogFile $LogFile

#Record Another REason Text
if ($WPFOSUninstall_AnotherReason.IsChecked -eq "True")
    {
    New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_TellUsMore" -PropertyType String -Value $($WPFOSUninstall_TellUsMore).Text -Force
    CMTraceLog -Message  "Setting RegKey OSUninstall_TellUsMore to $($WPFOSUninstall_TellUsMore).Text" -Type 1 -LogFile $LogFile
    }

# Record if OK to Contact User & Additional User Info
if ($WPFOSUninstall_ContactAllowedYes.IsChecked -eq "True")
    {
    New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_ContactAllowed" -PropertyType String -Value "True" -Force
    CMTraceLog -Message  "Setting RegKey OSUninstall_ContactAllowed to True" -Type 1 -LogFile $LogFile
    
    if ($WPFOSUninstall_ContactPerson.Text -ne $null)
        {
        New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_ContactPerson" -PropertyType String -Value $($WPFOSUninstall_ContactPerson).Text -Force
        CMTraceLog -Message  "Setting RegKey OSUninstall_ContactPerson to $($WPFOSUninstall_ContactPerson).Text" -Type 1 -LogFile $LogFile
        }
    }
    Else 
        {
        New-ItemProperty -Path $RegistryPathFull -Name "OSUninstall_ContactAllowed" -PropertyType String -Value "False" -Force
        CMTraceLog -Message  "Setting RegKey OSUninstall_ContactAllowed to False" -Type 1 -LogFile $LogFile
        }




start-sleep -Milliseconds 840

$form.Close()
})

$WPFButtonCancel.Add_Click({
Exit 1
start-sleep -Milliseconds 840
$form.Close()
})

CMTraceLog -Message  "---End $ScriptName---" -Type 2 -LogFile $LogFile

#===========================================================================
# Shows the form
#===========================================================================
write-host "To show the form, run the following" -ForegroundColor Cyan
$Form.ShowDialog() | out-null