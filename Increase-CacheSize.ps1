#This script is to increase the size of the config manager cache size so that you can deploy packages larger than 5GB
$Cache = Get-WmiObject -Namespace 'root\ccm\SoftMgmtAgent' -Class CacheConfig
$Cache.Size = '50000'
$Cache.Put()
Restart-Service -Name CcmExec
