foreach ($ApplicationName in $ApplicationNames) {
    $Id = "{0:D2}" -f $Count
    $AppId = "APPId$Id"
    $TSEnv.Value($AppId) = $ApplicationName
    $Count = $Count + 1
}