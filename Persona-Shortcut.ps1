# Create an Persona Shortcut
$TargetFile = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" 
$TargetSite = "http://137.229.186.123/CampusOnline/Login.aspx"
$ShortcutFile = "$env:Public\Desktop\Persona.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.WorkingDirectory = "%HOMEDRIVE%%HOMEPATH%"
$Shortcut.Arguments = $TargetSite
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()