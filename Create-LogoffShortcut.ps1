# Create a logoff shortcut on desktop
$TargetFile = "%SystemRoot%\System32\shutdown.exe"
$ShortcutFile = "$env:Public\Desktop\Log Off Machine.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.IconLocation = "%SystemRoot%\System32\shell32.dll, 27"
$Shortcut.Arguments="-l"
$Shortcut.Save()

