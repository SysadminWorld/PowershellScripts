# Get current user session ID for use in the task sequence service UI call

# Find out which user is using explorer and get the process id
$procid=get-process explorer |select -expand id

# Use that process id to see which session is using it
$sessionID = (Get-Process -PID $procid).SessionID

# Add the session ID to a custom Task Sequence Variable for use in the serviceui call
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$tsenv.Value("ActiveUserSession") = $sessionID