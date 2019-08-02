#Set the service smstsmgr to start automatically instead of manually. This should eliminate errors with the software center when trying to load.
Set-Service smstsmgr -StartupType Automatic
