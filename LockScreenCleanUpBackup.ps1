$TimeDelay = New-TimeSpan -Days 0 -Hours 2 -Minutes 30
$NewScheduleDate = (get-date) + $TimeDelay
$ScheduleDay = $NewScheduleDate.ToString("MM-dd-yyyy")
$ScheduleTime = $NewScheduleDate.ToLongTimeString()
$ScheduleTime = "{0:HH:mm}" -f [DateTime]$ScheduleTime

schtasks.exe /ru "SYSTEM" /Create /tn "ForceLockScreenCleanup2Hours" /tr "schtasks.exe /run /tn LockScreenCleanUp" /sc once /sd $ScheduleDay /st $ScheduleTime /F