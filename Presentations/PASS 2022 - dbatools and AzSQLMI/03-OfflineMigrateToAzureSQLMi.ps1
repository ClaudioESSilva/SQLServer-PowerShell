<#
    Migrate database with downtime (offline) - From SQL Server 2016+ and direct backup using WITH SAS CREDENTIAL
        1. Generate SAS key for BLOB Storage
        2. Create SQL Credential on source SQL Server instance
        3. Create SQL Credential on destination Azure SQL Managed Instance
        4. Backup database from source SQL Server instance to Azure Blob Storage using SAS credential
        5. Restore database from Azure Blob Storage to destination Azure SQL MI instance using SAS credential
#>

$onPremSQL = "localhost,1433"
$onPremSQLCred = Get-Credential -UserName "sqladmin" -Message "OnPrem login pwd"
$dbName = "dbatools"
$credentialName = "https://******.blob.core.windows.net/sqlbackups"
$AzureBaseUrl = "https://******.blob.core.windows.net/sqlbackups"

# 1. Generate SAS key for BLOB Storage
$sas = "sv=yourSASkey"

# 2. Create SQL Credential on source SQL Server instance
$splatDbaCredential = @{
	SqlInstance = $onPremSQL
    SqlCredential = $onPremSQLCred
	Name = $credentialName
	Identity = "SHARED ACCESS SIGNATURE"
	SecurePassword = (ConvertTo-SecureString $sas -AsPlainText -Force)
}
New-DbaCredential @splatDbaCredential

# 3. Create SQL Credential on destination Azure SQL Managed Instance
$splatDbaCredential = @{
	SqlInstance = $dbatoolsAzSQLMI
    SqlCredential = $dbatoolsAzSQLMICred
	Name = $credentialName
	Identity = "SHARED ACCESS SIGNATURE"
	SecurePassword = (ConvertTo-SecureString $sas -AsPlainText -Force)
}
New-DbaCredential @splatDbaCredential


# 4. Backup database from source SQL Server instance to Azure Blob Storage using SAS credential

# Confirm that we have a dbatools database on the source SQL Server instance
Get-DbaDatabase -SqlInstance $onPremSQL -SqlCredential $onPremSQLCred -Database $dbName

$backupFileName = "$dbName`_$((Get-Date).ToFileTime()).bak"

$splatBackupDbaDatabase = @{
    SqlInstance = $onPremSQL
    SqlCredential = $onPremSQLCred
    Database = $dbName
    BackupFileName = $backupFileName
    Type = "Full"
    Checksum = $true
    CompressBackup = $true
    CopyOnly = $true
    AzureBaseUrl = $AzureBaseUrl
    Verbose = $true
}
$AzureBlobBackup = Backup-DbaDatabase @splatBackupDbaDatabase
$AzureBlobBackup | Select-Object *

# 5. Restore database from Azure Blob Storage to destination Azure SQL MI instance using SAS credential 
# NOTE it also works with 'Managed Identity' credential
$splatRestoreDbaDatabase = @{
    SqlInstance = $dbatoolsAzSQLMI
    SqlCredential = $dbatoolsAzSQLMICred
    Database = "New_$dbName"
    Path = ($AzureBlobBackup | Select-Object -ExpandProperty Path)
    WithReplace = $true
    Verbose = $true
}
Restore-DbaDatabase @splatRestoreDbaDatabase