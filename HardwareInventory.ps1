# Trigger Configuration Manager Hardware Inventory
Get-WmiObject -Namespace root\ccm\invagt -Class InventoryActionStatus -Filter {InventoryActionID = '{00000000-0000-0000-0000-000000000001}'} | Remove-WmiObject
$SMSwmi = [wmiclass]"\root\ccm:SMS_Client"
$SMSwmi.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")
