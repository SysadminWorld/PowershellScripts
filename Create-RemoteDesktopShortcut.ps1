# Create a Remote Desktop Connection Shortcut with Windows PowerShell
$TargetFile = "mstsc.exe"
$ShortcutFile = "$env:Public\Desktop\Distance Education.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = "/v:krc-distance.ua.ad.alaska.edu /f /multimon"
$Shortcut.Save()

