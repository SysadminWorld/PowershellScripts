$Debug = $True

##Find Dell Command | Configure for 64-bit  
 $CCTK = Get-ChildItem -Path ${env:ProgramFiles(x86)}, $env:ProgramFiles -Filter cctk.exe -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.Directory -like '*x86_64*'}  
 ##Get all available Dell Command | Configure commands for current system  
 $Commands = Invoke-Command -ScriptBlock {c:\Windows\system32\cmd.exe /c $CCTK.FullName -h} -ErrorAction SilentlyContinue  
 ##Configure BIOS --wakeonlan=enable  
 #Test if wakeonlan exists on current system  
 If ($Commands -like '*wakeonlan*') {  
      [string]$WakeOnLANSetting = 'wakeonlan=enable'  
      [string]$Output = Invoke-Command -ScriptBlock {c:\Windows\system32\cmd.exe /c $CCTK.FullName --wakeonlan} -ErrorAction SilentlyContinue  
      If ($Output -ne $WakeOnLANSetting) {  
           $ErrCode = (Start-Process -FilePath $CCTK.FullName -ArgumentList ('--' + $WakeOnLANSetting) -Wait -Passthru).ExitCode  
           If ($ErrCode -eq 0) {  
                $WakeOnLAN = $true  
           } elseif ($ErrCode -eq 119) {  
                $WakeOnLAN = $true  
           } else {  
                $WakeOnLAN = $false  
           }  
           Remove-Variable -Name ErrCode  
      } else {  
           $WakeOnLAN = $true  
      }  
      Remove-Variable -Name WakeOnLANSetting  
      Remove-Variable -Name Output  
 }  
 ##Configure BIOS --deepsleepctrl=disable  
 #Test if deepsleepctrl exists on current system  
 If ($Commands -like '*deepsleepctrl*') {  
      [string]$DeepSleepCtrlSetting = 'deepsleepctrl=disable'  
      [string]$Output = Invoke-Command -ScriptBlock {c:\Windows\system32\cmd.exe /c $CCTK.FullName --deepsleepctrl} -ErrorAction SilentlyContinue  
      If ($Output -ne $DeepSleepCtrlSetting) {  
           $ErrCode = (Start-Process -FilePath $CCTK.FullName -ArgumentList ('--' + $DeepSleepCtrlSetting) -Wait -Passthru).ExitCode  
           If ($ErrCode -eq 0) {  
                $DeepSleepCtrl = $true  
           } elseif ($ErrCode -eq 119) {  
                $DeepSleepCtrl = $true  
           } else {  
                $DeepSleepCtrl = $false  
           }  
           Remove-Variable -Name ErrCode  
      }  
      Remove-Variable -Name DeepSleepCtrlSetting  
      Remove-Variable -Name Output  
 }  
 ##Configure BIOS --blocks3=disable  
 #Test if blocks3 exists on current system  
 If ($Commands -like '*blocks3*') {  
      [string]$BlockS3Setting = 'blocks3=disable'  
      [string]$Output = Invoke-Command -ScriptBlock { c:\Windows\system32\cmd.exe /c $CCTK.FullName --blocks3} -ErrorAction SilentlyContinue  
      If ($Output -ne $BlockS3Setting) {  
           $ErrCode = (Start-Process -FilePath $CCTK.FullName -ArgumentList ('--' + $BlockS3Setting) -Wait -Passthru).ExitCode  
           If ($ErrCode -eq 0) {  
                $BlockS3 = $true  
           } elseif ($ErrCode -eq 119) {  
                $BlockS3 = $true  
           } else {  
                $BlockS3 = $false  
           }  
           Remove-Variable -Name ErrCode  
      } else {  
           $BlockS3 = $true  
      }  
      Remove-Variable -Name BlockS3Setting  
      Remove-Variable -Name Output  
 }  
 ##Configure BIOS --cstatesctrl=disable  
 #Test if cstatesctrl exists on current system  
 If ($Commands -like '*cstatesctrl*') {  
      [string]$CStateCTRLSetting = 'cstatesctrl=disable'  
      [string]$Output = Invoke-Command -ScriptBlock { c:\Windows\system32\cmd.exe /c $CCTK.FullName --cstatesctrl} -ErrorAction SilentlyContinue  
      If ($Output -ne $CStateCTRLSetting) {  
           $ErrCode = (Start-Process -FilePath $CCTK.FullName -ArgumentList ('--' + $CStateCTRLSetting) -Wait -Passthru).ExitCode  
           If ($ErrCode -eq 0) {  
                $CStateCTRL = $true  
           } elseif ($ErrCode -eq 119) {  
                $CStateCTRL = $true  
           } else {  
                $CStateCTRL = $false  
           }  
           Remove-Variable -Name ErrCode  
      } else {  
           $CStateCTRL = $true  
      }  
      Remove-Variable -Name CStateCTRLSetting  
      Remove-Variable -Name Output  
 }  
 ##Disable Energy Efficient Ethernet  
 #Energy Efficient Ethernet disable registry value  
 $RegistryValue = '0'  
 #Find ethernet adapter  
 $Adapter = (Get-NetAdapter | Where-Object {($_.Status -eq 'Up') -and ($_.PhysicalMediaType -eq '802.3')}).Name  
 $DisplayName = (Get-NetAdapterAdvancedProperty -Name $Adapter | Where-Object {$_.DisplayName -like '*Efficient Ethernet*'}).DisplayName  
 #Test for presence of Energy-Efficient Ethernet  
 If ($DisplayName -like '*Efficient Ethernet*') {  
      [string]$CurrentState = (Get-NetAdapterAdvancedProperty -Name $Adapter -DisplayName $DisplayName).RegistryValue  
      If ($CurrentState -ne $RegistryValue) {  
           Set-NetAdapterAdvancedProperty -Name $Adapter -DisplayName $DisplayName -RegistryValue $RegistryValue  
           Do {  
                Try {  
                     [string]$CurrentState = (Get-NetAdapterAdvancedProperty -Name $Adapter -DisplayName $DisplayName).RegistryValue  
                     $Err = $false  
                } Catch {  
                     $Err = $true  
                }  
           } While ($Err -eq $true)  
           If ($RegistryValue -eq $CurrentState) {  
                $EnergyEfficientEthernet = $true  
           } else {  
                $EnergyEfficientEthernet = $false  
           }  
           Remove-Variable -Name Err  
      } else {  
           $EnergyEfficientEthernet = $true  
      }  
      Remove-Variable -Name RegistryValue  
      Remove-Variable -Name Adapter  
      Remove-Variable -Name DisplayName  
      Remove-Variable -Name CurrentState  
 }  
 ##Enable Wake on Magic Packet  
 $State = 'Enabled'  
 $Adapter = (Get-NetAdapter | Where-Object {($_.Status -eq 'Up') -and ($_.PhysicalMediaType -eq '802.3')}).Name  
 $DisplayName = (Get-NetAdapterAdvancedProperty -Name $Adapter | Where-Object {$_.DisplayName -like '*Magic Packet*'}).DisplayName  
 #Test if Magic Packet exists  
 If ($DisplayName -like '*Magic Packet*') {  
      [string]$CurrentState = (Get-NetAdapterPowerManagement -Name $Adapter).WakeOnMagicPacket  
      If ($CurrentState -ne $State) {  
           Set-NetAdapterPowerManagement -Name $Adapter -WakeOnMagicPacket $State  
           Do {  
                Try {  
                     [string]$CurrentState = (Get-NetAdapterPowerManagement -Name $Adapter).WakeOnMagicPacket  
                     $Err = $false  
                } Catch {  
                     $Err = $true  
                }  
           } While ($Err -eq $true)  
           If ($State -eq $CurrentState) {  
                $WakeOnMagicPacket = $true  
           } else {  
                $WakeOnMagicPacket = $false  
           }  
           Remove-Variable -Name Err  
      } else {  
           $WakeOnMagicPacket = $true  
      }  
      Remove-Variable -Name State  
      Remove-Variable -Name Adapter  
      Remove-Variable -Name DisplayName  
      Remove-Variable -Name CurrentState  
 }  
 ##Disable Shutdown Wake-On-Lan  
 $RegistryValue = '0'  
 $Adapter = (Get-NetAdapter | Where-Object {($_.Status -eq 'Up') -and ($_.PhysicalMediaType -eq '802.3')}).Name  
 $DisplayName = (Get-NetAdapterAdvancedProperty -Name $Adapter -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -eq 'Shutdown Wake-On-Lan'}).DisplayName  
 If ($DisplayName -eq 'Shutdown Wake-On-Lan') {  
      [string]$CurrentState = (Get-NetAdapterAdvancedProperty -Name $Adapter -DisplayName $DisplayName).RegistryValue  
      If ($CurrentState -ne $RegistryValue) {  
           Set-NetAdapterAdvancedProperty -Name $Adapter -DisplayName $DisplayName -RegistryValue $RegistryValue  
           Do {  
                Try {  
                     [string]$CurrentState = (Get-NetAdapterAdvancedProperty -Name $Adapter -DisplayName $DisplayName).RegistryValue  
                     $Err = $false  
                } Catch {  
                     $Err = $true  
                }  
           } While ($Err -eq $true)  
           If ($RegistryValue -eq $CurrentState) {  
                $ShutdownWakeOnLAN = $true  
           } else {  
                $ShutdownWakeOnLAN = $false  
           }  
           Remove-Variable -Name Err  
      } else {  
           $ShutdownWakeOnLAN = $true  
      }  
      Remove-Variable -Name RegistryValue  
      Remove-Variable -Name Adapter  
      Remove-Variable -Name DisplayName  
      Remove-Variable -Name CurrentState  
 }  
 ##Enable Allow the computer to turn off this device  
 $KeyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\'  
 #Test if KeyPath exists  
 If ((Test-Path $KeyPath) -eq $true) {  
      $PnPValue = 256  
      $Adapter = Get-NetAdapter | Where-Object {($_.Status -eq 'Up') -and ($_.PhysicalMediaType -eq '802.3')}  
      foreach ($Entry in (Get-ChildItem $KeyPath -ErrorAction SilentlyContinue).Name) {  
           If ((Get-ItemProperty REGISTRY::$Entry).DriverDesc -eq $Adapter.InterfaceDescription) {  
                $Value = (Get-ItemProperty REGISTRY::$Entry).PnPCapabilities  
                If ($Value -ne $PnPValue) {  
                     Set-ItemProperty -Path REGISTRY::$Entry -Name PnPCapabilities -Value $PnPValue -Force  
                     Disable-PnpDevice -InstanceId $Adapter.PnPDeviceID -Confirm:$false  
                     Enable-PnpDevice -InstanceId $Adapter.PnPDeviceID -Confirm:$false  
                     $Value = (Get-ItemProperty REGISTRY::$Entry).PnPCapabilities  
                }  
                If ($Value -eq $PnPValue) {  
                     $PowerManagement = $true  
                } else {  
                     $PowerManagement = $false  
                }  
                Remove-Variable -Name Value  
           }  
      }  
      Remove-Variable -Name PnPValue  
      Remove-Variable -Name Adapter  
      Remove-Variable -Name KeyPath  
 }  
 ##Disable Fast Startup  
 $KeyPath = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power"  
 #Test if KeyPath exists  
 If ((Test-Path -Path ('REGISTRY::' + $KeyPath)) -eq $true) {  
      Set-ItemProperty -Path ('REGISTRY::' + $KeyPath) -Name 'HiberbootEnabled' -Value 0  
      If ((Get-ItemProperty -Path ('REGISTRY::' + $KeyPath)).HiberbootEnabled -eq 0) {  
           $FastStartup = $false  
      } else {  
           $FastStartup = $true  
      }  
 }  

 If ($Debug){
     Write-Host 'Wake-On-LAN:'$WakeOnLAN  
     Write-Host 'Deep Sleep Control:'$DeepSleepCtrl  
     Write-Host 'BlockS3:'$BlockS3  
     Write-Host 'CState Control:'$CStateCTRL  
     Write-Host 'Energy Efficient Ethernet:'$EnergyEfficientEthernet  
     Write-Host 'Wake-On-Magic-Packet:'$WakeOnMagicPacket  
     Write-Host 'Shutdown Wake-On-LAN:'$ShutdownWakeOnLAN  
     Write-Host 'Allow Computer to Turn Off this Device:'$PowerManagement 
 } 

 If ((($WakeOnLAN -eq $null) -or ($WakeOnLAN -eq $true)) -and ($FastStartup -eq $false) -and (($DeepSleepCtrl -eq $null) -or ($DeepSleepCtrl -eq $true)) -and (($BlockS3 -eq $null) -or ($BlockS3 -eq $true)) -and (($CStateCTRL -eq $null) -or ($CStateCTRL -eq $true)) -and (($EnergyEfficientEthernet -eq $null) -or ($EnergyEfficientEthernet -eq $true)) -and (($WakeOnMagicPacket -eq $null) -or ($WakeOnMagicPacket -eq $true)) -and (($ShutdownWakeOnLAN -eq $null) -or ($ShutdownWakeOnLAN -eq $true)) -and (($PowerManagement -eq $null) -or ($PowerManagement -eq $true))) {  
      echo $true  
 } else {  
      echo $false  
 }  