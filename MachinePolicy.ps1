# Trigger Configuration Manager Machine Policy Update
$SMSwmi = [wmiclass]"\root\ccm:SMS_Client"
$SMSwmi.RequestMachinePolicy()