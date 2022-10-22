<#
    Migrate database with downtime (offline) - From Azure SQL MI with 'Managed Identity' to SQL Server (2022) OnPrem
        1. Generate SAS key for BLOB Storage
        2. Create SQL Credential on source SQL Server instance
        3. Create SQL Credential on destination Azure SQL Managed Instance
        4. Backup database from source SQL Server instance to Azure Blob Storage using SAS credential
        5. Restore database from Azure Blob Storage to destination Azure SQL MI instance using SAS credential
#>

$dbName = "New_dbatools"
$AzureBaseUrl = "https://******.blob.core.windows.net/sqlbackups"
$backupFileName = "$dbName`_FromSQLMI_$((Get-Date).ToFileTime()).bak"


# Replace current SAS credential by an Managed Identity credential
$managedIdentityParams = @{
    SqlInstance = $dbatoolsAzSQLMI
    SqlCredential = $dbatoolsAzSQLMIcred
    Name = $SQLCredentialName 
    Identity = "Managed Identity"
    Force = $true
    Verbose = $true
}
New-DbaCredential @managedIdentityParams

# Let's insert some data into the database on Azure SQL Managed Instance
$query = "CREATE TABLE dbo.IMAzureSQLMITable (C1 DATETIME, C2 VARCHAR(50))
INSERT INTO dbo.IMAzureSQLMITable (C1, C2) VALUES (GETDATE(), 'Cláudio Silva')"
$splatInvokeQuery = @{
    SqlInstance = $dbatoolsAzSQLMI
    SqlCredential = $dbatoolsAzSQLMIcred
    Database = $dbName
    Query = $query
}
Invoke-DbaQuery @splatInvokeQuery

# Check data is there
$query = "SELECT @@Servername as InstanceName, * FROM dbo.IMAzureSQLMITable"
$splatInvokeQuery = @{
    SqlInstance = $dbatoolsAzSQLMI
    SqlCredential = $dbatoolsAzSQLMIcred
    Database = $dbName
    Query = $query
}
Invoke-DbaQuery @splatInvokeQuery


# Backup database FROM SQL MI to BLOB Storage
<# 
    WARNING: [17:40:38][Backup-DbaDatabase] Backup Failed | Microsoft.Data.SqlClient.SqlError: 
    Cannot open backup device 'https://******.blob.core.windows.net/sqlbackups/New_dbatools_FromSQLMI_133095480363222824.bak'. 
    Operating system error 50(The request is not supported.).
#>
$splatDatabaseBackupToAZStorage = @{
    SqlInstance = $dbatoolsAzSQLMI
    SqlCredential = $dbatoolsAzSQLMIcred
    Database = $dbName
    AzureBaseUrl = $AzureBaseUrl
    BackupFileName = $backupFileName
    Type = "Full"
    Checksum = $true
    CopyOnly = $true # Mandatory!
    Verbose = $true
}
$AzureBlobBackup = Backup-DbaDatabase @splatDatabaseBackupToAZStorage
$AzureBlobBackup | Select-Object *


# Permissions are missing. Need to add a "Role Assignemnts" Show on Azure Portal

# With PowerShell
$SubscriptionID = Get-AzSubscription | Select-Object -ExpandProperty Id
# or
$SubscriptionID = "********-****-****-****-************"

$ServicePrincipalID = (Get-AzADServicePrincipal -DisplayName "dbatoolssqlmi") | Select-Object -ExpandProperty Id

$newRoleAssignment = @{
    RoleDefinitionName = "Storage Blob Data Contributor"
    PrincipalId = $ServicePrincipalID
    Scope = "/subscriptions/$SubscriptionID/resourceGroups/dbatools/providers/Microsoft.Storage/storageAccounts/dbatoolsmi"
}
$newAzRoleAssignment = New-AzRoleAssignment @newRoleAssignment
$newAzRoleAssignment | Select-Object *

<# 
    Now it will succeed
#>
$backupFileName = "$dbName`_FromSQLMI_$((Get-Date).ToFileTime()).bak"

$splatDatabaseBackupToAZStorage = @{
    SqlInstance = $dbatoolsAzSQLMI
    SqlCredential = $dbatoolsAzSQLMIcred
    Database = $dbName
    AzureBaseUrl = $AzureBaseUrl
    BackupFileName = $backupFileName
    Type = "Full"
    Checksum = $true
    CompressBackup = $true
    CopyOnly = $true # Mandatory!
    Verbose = $true
}
$AzureBlobBackup = Backup-DbaDatabase @splatDatabaseBackupToAZStorage
$AzureBlobBackup | Select-Object *




# 5. Restore database from Azure Blob Storage to destination OnPrem SQL Server instance using SAS credential
$splatRestoreDbaDatabase = @{
    SqlInstance = $onPremSQL
    SqlCredential = $onPremSQLCred
    Database = "$dbName`_FromSQLMI"
    Path = ($AzureBlobBackup | Select-Object -ExpandProperty Path)
    WithReplace = $true
    Verbose = $true
}
Restore-DbaDatabase @splatRestoreDbaDatabase


<#
    WARNING: [18:08:23][Restore-DbaDatabase] Failure | Microsoft.Data.SqlClient.SqlError: The database was backed up on a server running version 16.00.0537. 
    That version is incompatible with this server, which is running version 15.00.4223. Either restore the database on a server that supports the backup, or use a backup that is compatible with this server.
#>
$onPremSQL2022 = "localhost,2022"
$onPremSQL2022Cred = Get-Credential -UserName "sa" -Message "OnPrem 2022 login pwd"


# Create SQL Credential on source SQL Server instance
$splatDbaCredential = @{
	SqlInstance = $onPremSQL2022
    SqlCredential = $onPremSQL2022Cred
	Name = $credentialName
	Identity = "SHARED ACCESS SIGNATURE"
	SecurePassword = (ConvertTo-SecureString $sas -AsPlainText -Force)
}
New-DbaCredential @splatDbaCredential



$splatRestoreDbaDatabase = @{
    SqlInstance = $onPremSQL2022
    SqlCredential = $onPremSQL2022Cred
    Database = "$dbName`_FromSQLMI"
    Path = ($AzureBlobBackup | Select-Object -ExpandProperty Path)
    WithReplace = $true
    Verbose = $true
}
Restore-DbaDatabase @splatRestoreDbaDatabase


# Check data is there - OnPrem
$query = "SELECT @@Servername as InstanceName, * FROM dbo.IMAzureSQLMITable"
$splatInvokeQuery = @{
    SqlInstance = $onPremSQL2022
    SqlCredential = $onPremSQL2022Cred
    Database = "$dbName`_FromSQLMI"
    Query = $query
}
Invoke-DbaQuery @splatInvokeQuery