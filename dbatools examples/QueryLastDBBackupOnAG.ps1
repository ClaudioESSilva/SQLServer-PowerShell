#This works if you can connect through your replica name
$sqlInstance = "<LISTENER>or<One of the instances - if only one AG>"
$database = "<DBNAME>"

$AGInfo = Get-DbaAvailabilityGroup -SqlInstance $sqlInstance -
$listBackups = Get-DbaBackupHistory -SqlInstance $AGInfo.ReplicaName -Database $database -Last
$listBackups | Sort-Object Start -Descending
