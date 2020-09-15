Return 'Cláudio, come on, you are giving a presentation..do not try to run the whole script! :) '

# Lets back up those new databases to a local path
$splatBackup = @{
    SqlInstance = $sql2016
    Database = "dbatools", "dbatoolsBestPractices"
    BackupDirectory = "D:\temp"
}
Backup-DbaDatabase @splatBackup

# Open folder
Invoke-Item "D:\temp"


# View backup history
Get-DbaDbBackupHistory -SqlInstance $sql2016


# Only last backup
$splatBackupHist = @{
    SqlInstance = $sql2016
    Database = "OrphanUser"
    Last = $true
}
Get-DbaDbBackupHistory @splatBackupHist

# Few information? Remember that you can use *
Get-DbaDbBackupHistory -SqlInstance $sql2016 | Select-Object *

# What sorcery is that? :-) Open results in a grid view, select and open the path of the select line
Get-DbaDbBackupHistory -SqlInstance $sql2016 | Select-Object * | Out-GridView -PassThru | Select-Object -ExpandProperty Path | Split-Path -Parent | Invoke-Item


# Do you test your backups right?! ;-) (you can use a different instance with -Destination parameter)
Test-DbaLastBackup -SqlInstance $sql2016 -Database dbatools | Out-GridView



# Select databases to backup and run with CopyOnly
Get-DbaDatabase -SqlInstance $sql2016 | Out-GridView -PassThru | Backup-DbaDatabase -CopyOnly -Path "D:\temp" -CompressBackup


# Please restore a copy of Pubs on docker1 to docker2 instance
Backup-DbaDatabase -SqlInstance $docker1 -SqlCredential $sqlCredential -Database pubs -CopyOnly -BackupDirectory /tmp | Restore-DbaDatabase -SqlInstance $docker2 -SqlCredential $sqlCredential #-WithReplace


# Get all backups from a folder and retore them on the server
#Invoke-Item \\sharedPath\sql\backups\SQL2016
#Get-ChildItem -Directory \\sharedPath\sql\backups\SQL2016 | Restore-DbaDatabase -SqlInstance $sql2016


# Backup.bak?! What is inside? Read backup header
$backup = "D:\temp\SomeBackup.bak"
Read-DbaBackupHeader -SqlInstance $sql2016 -Path $backup | Select-Object ServerName, DatabaseName, UserName, BackupFinishDate, SqlVersion, BackupSize




