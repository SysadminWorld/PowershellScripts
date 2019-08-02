Function Remove-ACL {    
    [CmdletBinding(SupportsShouldProcess=$True)]
    Param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [String[]]$Folder,
        [Switch]$Recurse
    )

    Process {

        foreach ($f in $Folder) {

            if ($Recurse) {$Folders = $(Get-ChildItem $f -Recurse -Directory).FullName} else {$Folders = $f}

            if ($Folders -ne $null) {

                $Folders | ForEach-Object {

                    # Remove inheritance
                    $acl = Get-Acl $_
                    $acl.SetAccessRuleProtection($true,$true)
                    Set-Acl $_ $acl

                    # Remove ACL
                    $acl = Get-Acl $_
                    $acl.Access | %{$acl.RemoveAccessRule($_)} | Out-Null

                    # Add local admin
                    $permission  = "BUILTIN\Administrators","FullControl", "ContainerInherit,ObjectInherit","None","Allow"
                    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                    $acl.SetAccessRule($rule)

                    Set-Acl $_ $acl

                    Write-Verbose "Remove-HCacl: Inheritance disabled and permissions removed from $_"
                }
            }
            else {
                Write-Verbose "Remove-HCacl: No subfolders found for $f"
            }
        }
    }
}
Remove-ACL C:\_SMSTaskSequence -Recurse