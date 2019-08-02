param(
 [bool] $DeletePersistent
)
$CMObject = New-Object -ComObject "UIResource.UIResourceMgr"
$CMCacheObjects = $CMObject.GetCacheInfo()
$CMCacheElements = $CMCacheObjects.GetCacheElements()
foreach ($CMCacheElement in $CMCacheElements)
{
    if ($DeletePersistent -eq $true)
    {
        $CMCacheObjects.DeleteCacheElementEx($CMCacheElement.CacheElementId, $true)
    }
    else
    {
        $CMCacheObjects.DeleteCacheElement($CMCacheElement.CacheElementId)
    }
}