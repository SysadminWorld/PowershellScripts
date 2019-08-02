function Get-LogDate {
     
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
     
} 
  
$Script:my_user = (gwmi win32_computersystem).username
$SystemRoot = $env:SystemRoot
$Log_File = "$SystemRoot\Debug\Add_Windows_Sandbox_Feature.log"
If((test-path $Log_File))
 {
  remove-item $Log_File -force
 }
  
new-item $Log_File -type file -force
  
  
Add-Content $Log_File  "Script for adding the Windows Sandbox feature"
Add-Content $Log_File  "---------------------------------------------------------"
  
Add-Content $Log_File  "$(Get-LogDate) - Add_Windows_Sandbox_Feature_v1.0 is starting"
Add-Content $Log_File  "" 
 
Add-Content $Log_File  "$(Get-LogDate) - Checking the current Windows Sandbox status" 
$Sandbox_Status = $False 
$WindowsFeature = "Containers-DisposableClientVM"
try 
{
    $WindowsFeatureState = (Get-WindowsOptionalFeature -FeatureName $WindowsFeature -Online).State
 If($WindowsFeatureState -eq "Enabled") 
  {
   $Sandbox_Status = $True
   Add-Content $Log_File  "$(Get-LogDate) - The Sandbox feature is already enabled"          
  } 
 Else 
  {
   Add-Content $Log_File  "$(Get-LogDate) - The Sandbox feature is not enabled"            
   $Sandbox_Status = $False   
   Try 
    {
     Add-Content $Log_File  "$(Get-LogDate) - The Sandbox feature is being enabled"                
     Enable-WindowsOptionalFeature -FeatureName $WindowsFeature -Online -NoRestart -ErrorAction Stop
     Add-Content $Log_File  "$(Get-LogDate) - The Sandbox feature has been successfully enabled"   
     $Sandbox_Status = $True     
    }
   catch 
    {
     Add-Content $Log_File  "$(Get-LogDate) - Failed to enable the Sandbox feature"          
    }
  }   
}
catch 
{
 Add-Content $Log_File  "$(Get-LogDate) - Failed to enable the Sandbox feature"          
}
 
If($Sandbox_Status -eq $True)
 {
  Add-Content $Log_File  ""   
  Add-Content $Log_File  "$(Get-LogDate) - Checking if the current user is member of the Hyper-V administrators group" 
  $Get_HyperV_Users = get-LocalGroupMember -group "Hyper-V administrators" | where {$_.Name -like "*$my_user*"}
  If($Get_HyperV_Users -eq $null)
   {
    Add-Content $Log_File  "$(Get-LogDate) - Current user name is $my_user"
    Add-Content $Log_File  "$(Get-LogDate) - The user $my_user is not member of the group Hyper-V administrators"   
    Try
     {
      Add-LocalGroupMember -group "Hyper-V administrators" -member $my_user  
      Add-Content $Log_File  "$(Get-LogDate) - The user $my_user has been successfully added in the group Hyper-V administrators"       
     }
    Catch
     {
      Add-Content $Log_File  "$(Get-LogDate) - An issue occured while adding the user $my_user in the group Hyper-V administrators"          
     }
   }   
 }
 
Add-Content $Log_File  "$(Get-LogDate) - Add_Windows_Sandbox_Feature_v1.0 finished" 