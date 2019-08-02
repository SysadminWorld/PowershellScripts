# Create an Excel Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files (x86)\Microsoft Office\Office16\Excel.exe"
$ShortcutFile = "$env:Public\Desktop\Excel.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Create an Powerpoint Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files (x86)\Microsoft Office\Office16\powerpnt.exe"
$ShortcutFile = "$env:Public\Desktop\PowerPoint.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Create an Project Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files (x86)\Microsoft Office\Office16\winproj.exe"
$ShortcutFile = "$env:Public\Desktop\Project.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Create an Visio Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files (x86)\Microsoft Office\Office16\Visio.exe"
$ShortcutFile = "$env:Public\Desktop\Visio.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Create an Word Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files (x86)\Microsoft Office\Office16\Winword.exe"
$ShortcutFile = "$env:Public\Desktop\Word.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
