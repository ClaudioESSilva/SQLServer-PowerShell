#This works if you can connect through your replica name
$sqlInstance = "<LISTENER>or<One of the instances - if only one AG>"
$database = "<DBNAME>"

$AGInfo = Get-DbaAvailabilityGroup -SqlInstance $sqlInstance -
$listBackups = Get-DbaBackupHistory -SqlInstance $AGInfo.ReplicaName -Database $database -Last

#To get all results
$listBackups | Sort-Object Start -Descending

# If you want just the most recent
$listBackups | Sort-Object Start -Descending | Select-Object -First 1

#Use * to get more information about the backup
$listBackups | Sort-Object Start -Descending | Select-Object * -First 1
