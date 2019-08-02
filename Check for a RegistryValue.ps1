<#
.Synopsis
   Reading a Registry key if it exist or not.
.DESCRIPTION
   Reading a registrykey if it exist then write (1=True) (0=False)
   By Pontus Wendt
#>
function Get-Registrykey
{
    [CmdletBinding()]
    param ()
   

    Begin
    {
    }
    Process
    {
    Try {
    $Result = Test-Path "HKLM:\Software\Classes\MJ"
     
    ForEach-Object {
            If($Result -match "True") { 
                $State = 1} 
            ElseIf($Result -match "False") {
                $State = 0} 
                    }
     }
   catch {
   # Error hantering
   
   }
   $state


    }
    End
    {
    }
}

Get-Registrykey