[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true,Position=1,HelpMessage="ContentIDs")]
    [ValidateNotNullOrEmpty()]
    [String[]]$CacheItemsToDelete
)
ForEach ($CacheItemsToDelete in $CacheItemsToDelete)
{
$pkgver = (Get-ItemPropertyValue "HKLM:\SOFTWARE\1E\NomadBranch\PkgStatus\$CacheItemsToDelete" 'version')
cmd.exe /c "CacheCleaner.exe -deletepkg=$CacheItemsToDelete -pkgver=$pkgver"
}