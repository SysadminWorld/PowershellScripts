 &lt;#   
    .SYNOPSIS   
        Sets the PC Volume to "MUTE"
         
    .DESCRIPTION   
        Sets the PC Volume to mute and volume to 0
        This script uses the AudioDevice Cmdlet from https://github.com/cdhunt/WindowsAudioDevice-Powershell-Cmdlet
        
    .PARAMETER (none)
      
         
    .NOTES   
        Author: Alex Verboon
        Version: 1.0       
            - initial version
     
    .EXAMPLE 
    SetPCVolumeMute.ps1     
  
    #&gt;         



# Get the current script Name
$ScriptName = $MyInvocation.MyCommand.Name

# Get Current Script Path
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# Import module (module DLL is stored in same path as the script)
$AudioModuleName = $scriptPath + "\AudioDeviceCmdlets.dll"
Import-Module -Name $AudioModuleName
Set-DefaultAudioDeviceMute
# if the volume was already muted, the above command unmutes it, so we also 
# set the volume to 0
Set-DefaultAudioDeviceVolume 0