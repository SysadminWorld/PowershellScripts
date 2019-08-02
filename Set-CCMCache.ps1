$Cache = Get-WmiObject -namespace root\ccm\SoftMgmtAgent -class CacheConfig 
$Cache.size = '100000' 
$Cache.InUse = "True" 
$Cache.Put() 
Restart-Service ccmexec