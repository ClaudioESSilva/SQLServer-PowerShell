<#
- Database refresh
1. Export users on destination
2. Backup source database and restore it on destination
3. Run data masking (If used)
4. Run exported permissions on step 1
5. Fix/remove orphan users

NOTE: If you need this process but for databases that belongs to Availability Groups read my blog post:
 Refresh databases that belongs to Availability Group using dbatools
 (https://claudioessilva.eu/2020/05/20/refresh-databases-that-belongs-to-availability-group-using-dbatools/)
#>

# Set variables
$dbatools1 = "localhost,1433"
$dbatools2 = "localhost,14333"
$secureString = ConvertTo-SecureString "dbatools.IO" -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sqladmin", $secureString
$databaseToRefresh = "dbatools"


# 1 - Export users on destination

# Export the user from the specific database and its permissions at database-roles and object level
$usersExport = Export-DbaUser -SqlInstance $dbatools2 -SqlCredential $cred -Database $databaseToRefresh -Passthru

$usersExport

# 2 - Backup source database and restore it on destination
$copyDatabaseSplat = @{
    Source = $dbatools1
    SourceSqlCredential = $cred
    Destination = $dbatools2
    DestinationSqlCredential = $cred
    Database = $databaseToRefresh
    BackupRestore = $true
    SharedPath = "/tmp"
    WithReplace = $true
}
Copy-DbaDatabase @copyDatabaseSplat


# Verify the orphan users
Get-DbaDbOrphanUser -SqlInstance $dbatools2 -SqlCredential $cred -Database $databaseToRefresh

# Repair Orphan users
Repair-DbaDbOrphanUser -SqlInstance $dbatools2 -SqlCredential $cred -Database $databaseToRefresh

# Remove Orphan Users
Remove-DbaDbOrphanUser -SqlInstance $dbatools2 -SqlCredential $cred -Database $databaseToRefresh -Verbose


# Recreate users and grant permissions from the exported command
# Run the exported script
$sqlInst = Connect-DbaInstance $dbatools2 -SqlCredential $cred
$sqlInst.Databases["master"].ExecuteNonQuery($usersExport)

# Confirm that we don't have orphan users
Get-DbaDbOrphanUser -SqlInstance $dbatools2 -SqlCredential $cred -Database $databaseToRefresh -Verbose


# Connect as dbatools_dev and try to select some data

# Test connect as dbatools_dev and select table where it does not have permissions
$cred_dev = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "dbatools_dev", $secureString
Invoke-DbaQuery -SqlInstance $dbatools2 -SqlCredential $cred_dev -Database $databaseToRefresh -Query "SELECT SUSER_NAME()"