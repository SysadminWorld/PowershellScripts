# Create an AK Warm Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files (x86)\AHFC\AkWarm\akwarm.exe"
$ShortcutFile = "$env:Public\Desktop\AK Warm.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Create an Bluebeam Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files\Bluebeam Software\Bluebeam Revu\2016\Revu\Revu.exe"
$ShortcutFile = "$env:Public\Desktop\Bluebeam Revu 2016.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Create an Planswift Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files (x86)\PlanSwift10\PlanSwift.exe"
$ShortcutFile = "$env:Public\Desktop\Planswift 10.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Create an Lumion Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files\Lumion 7.0.1\Lumion.exe"
$ShortcutFile = "$env:Public\Desktop\Lumion 7.0.1.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Create an Autodesk Design Review Shortcut with Windows PowerShell
$TargetFile = "C:\Program Files (x86)\Autodesk\Autodesk Design Review 2013\DesignReview.exe"
$ShortcutFile = "$env:Public\Desktop\Autodesk Design Review 2013.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()