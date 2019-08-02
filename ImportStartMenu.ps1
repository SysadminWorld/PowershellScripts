# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

# Create a Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files\Internet Explorer\iexplore.exe"
$ShortcutFile = "c:\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

Copy-Item "$ScriptPathParent\startmenu.xml" "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\" -Force | Out-Null

#Import the customized Start Menu Layout
Import-StartLayout -LayoutPath $ScriptPathParent\startmenu.xml -MountPath $env:SystemDrive\ | Out-Null
Import-StartLayout -LayoutPath "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\StartMenu.xml" -MountPath $env:SystemDrive\ | Out-Null

