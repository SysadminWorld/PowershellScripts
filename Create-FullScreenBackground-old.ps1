# 2019-03-20 Modified by @gwblok to have the Text Array cycle the entire time vs the orginal that cycles once and leaves a static message. 

# Creates a full screen 'background' styled for a Windows 10 upgrade, and hides the task bar
# Called by the "Show-OSUpgradeBackground" script

Param($DeviceName)

# Add required assemblies
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Windows.Forms,System.Drawing
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
Add-Type -Path "$PSSCriptRoot\bin\MahApps.Metro.dll"
Add-Type -Path "$PSSCriptRoot\bin\System.Windows.Interactivity.dll"

# Find screen by DeviceName
$Screens = [System.Windows.Forms.Screen]::AllScreens
$Screen = $Screens | Where {$_.DeviceName -eq $DeviceName}

# Add custom type to hide the taskbar
# Thanks to https://stackoverflow.com/questions/25499393/make-my-wpf-application-full-screen-cover-taskbar-and-title-bar-of-window
$Source = @"
using System;
using System.Runtime.InteropServices;

public class Taskbar
{
    [DllImport("user32.dll")]
    private static extern int FindWindow(string className, string windowText);
    [DllImport("user32.dll")]
    private static extern int ShowWindow(int hwnd, int command);

    private const int SW_HIDE = 0;
    private const int SW_SHOW = 1;

    protected static int Handle
    {
        get
        {
            return FindWindow("Shell_TrayWnd", "");
        }
    }

    private Taskbar()
    {
        // hide ctor
    }

    public static void Show()
    {
        ShowWindow(Handle, SW_SHOW);
    }

    public static void Hide()
    {
        ShowWindow(Handle, SW_HIDE);
    }
}
"@
Add-Type -ReferencedAssemblies 'System', 'System.Runtime.InteropServices' -TypeDefinition $Source -Language CSharp

# Find the user identity from the domain if possible
Try
{
    $PrincipalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new([System.DirectoryServices.AccountManagement.ContextType]::Domain, [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain())
    $GivenName = ([System.DirectoryServices.AccountManagement.Principal]::FindByIdentity($PrincipalContext,[System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName,[Environment]::UserName)).GivenName
    $PrincipalContext.Dispose()
}
Catch {}

# Create a WPF window
$Window = New-Object System.Windows.Window
$window.Background = "#012a47"
$Window.WindowStyle = [System.Windows.WindowStyle]::None
$Window.ResizeMode = [System.Windows.ResizeMode]::NoResize
$Window.Foreground = [System.Windows.Media.Brushes]::White
$window.Topmost = $True

# Get the bounds of the primary screen
$Bounds = $Screen.Bounds

# Assemble a grid
$Grid = New-object System.Windows.Controls.Grid
$Grid.Width = "NaN"
$Grid.Height = "NaN"
$Grid.HorizontalAlignment = "Stretch"
$Grid.VerticalAlignment = "Stretch"

# Add a column
$Column = New-Object System.Windows.Controls.ColumnDefinition
$Grid.ColumnDefinitions.Add($Column)

# Add rows
$Row = New-Object System.Windows.Controls.RowDefinition
$Row.Height = "1*"
$Grid.RowDefinitions.Add($Row)
$Row = New-Object System.Windows.Controls.RowDefinition
$Row.Height = [System.Windows.GridLength]::Auto
$Grid.RowDefinitions.Add($Row)
$Row = New-Object System.Windows.Controls.RowDefinition
$Row.Height = [System.Windows.GridLength]::Auto
$Grid.RowDefinitions.Add($Row)
$Row = New-Object System.Windows.Controls.RowDefinition
$Row.Height = "1*"
$Grid.RowDefinitions.Add($Row)

# Add a progress ring
$ProgressRing = [MahApps.Metro.Controls.ProgressRing]::new()
$ProgressRing.Opacity = 0
$ProgressRing.IsActive = $false
$ProgressRing.Margin = "0,0,0,60"
$Grid.AddChild($ProgressRing)
$ProgressRing.SetValue([System.Windows.Controls.Grid]::RowProperty,1)

# Add a textblock
$TextBlock = New-Object System.Windows.Controls.TextBlock
If ($GivenName)
{
    $TextBlock.Text = "Hi $GivenName"
}
Else
{
    $TextBlock.Text = "Hi there"
}
$TextBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
$TextBlock.MaxWidth = $Bounds.Width
$TextBlock.Margin = "0,0,0,120"
$TextBlock.FontSize = 50
$TextBlock.FontWeight = [System.Windows.FontWeights]::Light
$TextBlock.VerticalAlignment = "Top"
$TextBlock.HorizontalAlignment = "Center"
$TextBlock.Opacity = 0
$Grid.AddChild($TextBlock)
$TextBlock.SetValue([System.Windows.Controls.Grid]::RowProperty,2)

# Add a textblock
$TextBlock2 = New-Object System.Windows.Controls.TextBlock
$TextBlock2.Margin = "0,0,0,60"
$TextBlock2.Text = "Don't turn off your PC"
$TextBlock2.TextWrapping = [System.Windows.TextWrapping]::Wrap
$TextBlock2.MaxWidth = $Bounds.Width
$TextBlock2.FontSize = 25
$TextBlock2.FontWeight = [System.Windows.FontWeights]::Light
$TextBlock2.VerticalAlignment = "Bottom"
$TextBlock2.HorizontalAlignment = "Center"
$TextBlock2.Opacity = 0
$Grid.AddChild($TextBlock2)
$TextBlock2.SetValue([System.Windows.Controls.Grid]::RowProperty,3)

# Add a textblock
$TextBlock3 = New-Object System.Windows.Controls.TextBlock
$TextBlock3.Margin = "0,0,0,120"
$TextBlock3.Text = "Task Sequence Step Should be Here"
$TextBlock3.TextWrapping = [System.Windows.TextWrapping]::Wrap
$TextBlock3.MaxWidth = $Bounds.Width
$TextBlock3.FontSize = 15
$TextBlock3.FontWeight = [System.Windows.FontWeights]::Light
$TextBlock3.VerticalAlignment = "Bottom"
$TextBlock3.HorizontalAlignment = "Center"
$TextBlock3.Opacity = 0
$Grid.AddChild($TextBlock3)
$TextBlock3.SetValue([System.Windows.Controls.Grid]::RowProperty,4)

# Add a textblock
$TextBlock4 = New-Object System.Windows.Controls.TextBlock
$TextBlock4.Margin = "0,0,60,60"
$TextBlock4.Text = "Setup Engine %"
$TextBlock4.TextWrapping = [System.Windows.TextWrapping]::Wrap
$TextBlock4.MaxWidth = $Bounds.Width
$TextBlock4.FontSize = 30
$TextBlock4.FontWeight = [System.Windows.FontWeights]::Light
$TextBlock4.VerticalAlignment = "Bottom"
$TextBlock4.HorizontalAlignment = "Right"
$TextBlock4.Opacity = 0
$Grid.AddChild($TextBlock4)
$TextBlock4.SetValue([System.Windows.Controls.Grid]::RowProperty,5)

# Add to window
$Window.AddChild($Grid)

# Create some animations
$FadeinAnimation = [System.Windows.Media.Animation.DoubleAnimation]::new(0,1,[System.Windows.Duration]::new([Timespan]::FromSeconds(3)))
$FadeOutAnimation = [System.Windows.Media.Animation.DoubleAnimation]::new(1,0,[System.Windows.Duration]::new([Timespan]::FromSeconds(3)))
$ColourBrighterAnimation = [System.Windows.Media.Animation.ColorAnimation]::new("#012a47","#1271b5",[System.Windows.Duration]::new([Timespan]::FromSeconds(5)))
$ColourDarkerAnimation = [System.Windows.Media.Animation.ColorAnimation]::new("#1271b5","#012a47",[System.Windows.Duration]::new([Timespan]::FromSeconds(5)))


#Gary Modifications
$RegistryPath = "HKLM:\SOFTWARE\WaaS"
$LogFile = "C:\Windows\ccm\Logs\CustomFullScreenBackground.log"
$LastOSUpgradeFrom = Get-ItemPropertyValue -Path "$RegistryPath" -Name LastOSUpgradeFrom
$LastOSUpgradeTo = Get-ItemPropertyValue -Path "$RegistryPath" -Name LastOSUpgradeTo
try
{
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    
}
catch
{
	Write-Verbose "Not running in a task sequence."
}

# An array of sentences to display, in order. Leave the first one blank as the 0 index gets skipped.
$TextArray = @(
    "This Line never actually displays"
    "We're upgrading you to Windows 10 $LastOSUpgradeTo"
    "It may take 60 - 120 minutes"
    "Your PC will restart several times"
    "Should anything go wrong, contact your..."
    "... Local Service Desk ..."
    "Other Ideas while you wait"
    "Take this opportunity clean your work area"
    "Checkout GARYTOWN.COM"
    "Update your profile on Teams"
    "Like our Company Page on FaceBook"
    "Review the Company HR Guidelines"
)
$script:i = 0
# Start a dispatcher timer. This is used to control when the sentences are changed.
$TimerCode = {

    $ProgressRing.IsActive = $True
    
    # The IF statement number should equal the number of sentences in the TextArray
    $NumberofElements = $TextArray.Count -1
    If ($script:i -lt $NumberofElements)
    {
        $FadeoutAnimation.Add_Completed({            
            $TextBlock.Opacity = 0
            $TextBlock.Text = $TextArray[$script:i]
            $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)

        })   
        $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeoutAnimation) 
    }
    # The final sentence to display ongoing
    ElseIf ($script:i -eq $NumberofElements)
    {
        $script:i = 0
        $FadeoutAnimation.Add_Completed({            
            $TextBlock.Opacity = 0
            $TextBlock.Text = "We're upgrading this PC to Windows 10 $LastOSUpgradeTo"
            $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)

        })   
        $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeoutAnimation) 
    }
    Else
        {
        # Restore the taskbar
        [Taskbar]::Show()

        # Restore the mouse cursor
        [System.Windows.Forms.Cursor]::Show()

        $DispatcherTimer.Stop()
        $DispatcherTimerTS.Stop()
        exit
        }

    try
    {
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    
    }
    catch
    {
	Write-Verbose "Not running in a task sequence."
    }
    
    if ($tsenv)
        {
        if ($tsenv.Value('_SMSTSCurrentActionName') -eq "Launch Custom Dialog") 
            {
            # Restore the taskbar
            [Taskbar]::Show()

            # Restore the mouse cursor
            [System.Windows.Forms.Cursor]::Show()

            $DispatcherTimer.Stop()
            $DispatcherTimerTS.Stop()
            $DispatcherTimerUpgrade.Stop()
            Exit
            }
         if ($DispatcherTimerTS.IsEnabled -and $tsenv.Value('_SMSTSCurrentActionName') -eq "Upgrade Operating System. DO NOT TURN OFF YOUR PC") {$DispatcherTimerTS.Stop()}
         if ($DispatcherTimerUpgrade.IsEnabled -eq $false -and $tsenv.Value('_SMSTSCurrentActionName') -eq "Upgrade Operating System. DO NOT TURN OFF YOUR PC") {$DispatcherTimerUpgrade.Start()}
        }
    Else 
        {
        # Restore the taskbar
        [Taskbar]::Show()

        # Restore the mouse cursor
        [System.Windows.Forms.Cursor]::Show()

        $DispatcherTimer.Stop()
        $DispatcherTimerTS.Stop()
        $DispatcherTimerUpgrade.Stop()
        Exit
        }

    $ColourBrighterAnimation.Add_Completed({            
        $Window.Background.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty,$ColourDarkerAnimation)
    })   
    $Window.Background.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty,$ColourBrighterAnimation)

    $Script:i++
}
$DispatcherTimer = New-Object -TypeName System.Windows.Threading.DispatcherTimer
$DispatcherTimer.Interval = [TimeSpan]::FromSeconds(10)
$DispatcherTimer.Add_Tick($TimerCode)

$TimerCodeTS = {
        
        $TestInfo = $tsenv.Value('_SMSTSCurrentActionName')
        $TextBlock3.Text = "$($TestInfo) %"

}
$DispatcherTimerTS = New-Object -TypeName System.Windows.Threading.DispatcherTimer
$DispatcherTimerTS.Interval = [TimeSpan]::FromMilliseconds(500)
$DispatcherTimerTS.Add_Tick($TimerCodeTS)

    
$TimerCodeUpgrade = {
        
        
        $TestInfoUpgrade = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\Setup\MoSetup\Volatile" -Name "SetupProgress"
        $TextBlock4.Text = "Windows Setup Engine $($TestInfoUpgrade) %"

}
$DispatcherTimerUpgrade = New-Object -TypeName System.Windows.Threading.DispatcherTimer
$DispatcherTimerUpgrade.Interval = [TimeSpan]::FromSeconds(5)
$DispatcherTimerUpgrade.Add_Tick($TimerCodeUpgrade)



# Event: Window loaded
$Window.Add_Loaded({
    
    # Activate the window to bring it to the fore
    $This.Activate()

    # Fill the screen
    $Bounds = $screen.Bounds
    $Window.Left = $Bounds.Left
    $Window.Top = $Bounds.Top
    $Window.Height = $Bounds.Height
    $Window.Width = $Bounds.Width

    # Hide the taskbar
    [TaskBar]::Hide()

    # Hide the mouse cursor
    [System.Windows.Forms.Cursor]::Hide()

    # Begin animations
    $TextBlock.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)
    $TextBlock2.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)
    $TextBlock3.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)
    $ProgressRing.BeginAnimation([System.Windows.Controls.TextBlock]::OpacityProperty,$FadeinAnimation)
    $ColourBrighterAnimation.Add_Completed({            
        $Window.Background.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty,$ColourDarkerAnimation)
    })   
    $Window.Background.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty,$ColourBrighterAnimation)

})

# Event: Window closing
$Window.Add_Closing({

    # Restore the taskbar
    [Taskbar]::Show()

    # Restore the mouse cursor
    [System.Windows.Forms.Cursor]::Show()

    $DispatcherTimer.Stop()
    $DispatcherTimerTS.Stop()
    $DispatcherTimerUpgrade.Stop()
})

# Event: Allows to close the window on right-click (uncomment for testing)
<#
$Window.Add_MouseRightButtonDown({

    $This.Close()

})
#>

# Display the window
$DispatcherTimer.Start()
$DispatcherTimerTS.Start()
$Window.ShowDialog()
