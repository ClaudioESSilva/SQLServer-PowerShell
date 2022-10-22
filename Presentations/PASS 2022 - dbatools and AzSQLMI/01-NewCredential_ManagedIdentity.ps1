<#
    Create SQL Credential of identity type "Managed Identity"
    Example: Useful to do on-demand database backups (replace the need of SAS keys).
        It requires some IAM configuration to grant "Storage Blob Data Contributor" role to the SQL Managed Instance.

    LINK: https://techcommunity.microsoft.com/t5/azure-sql-blog/how-to-take-secure-on-demand-backups-on-sql-managed-instance/ba-p/3638369
#>

# This is the URL to your storage account and blob container
# ex: "https://<azure storage account name>.blob.core.windows.net/<blob container>"
$SQLCredentialName = "https://******.blob.core.windows.net/sqlbackups"

$dbatoolsAzSQLMI = "sqlmi.public.******.database.windows.net,3342"
$dbatoolsAzSQLMIcred = Get-Credential -UserName "<login>" -Message "Azure SQL MI pwd"

$managedIdentityParams = @{
    SqlInstance = $dbatoolsAzSQLMI
    SqlCredential = $dbatoolsAzSQLMIcred
    Name = $SQLCredentialName 
    Identity = "Managed Identity"
    Verbose = $true
}
New-DbaCredential @managedIdentityParams

# Verify that credential exists
Get-DbaCredential -SqlInstance $dbatoolsAzSQLMI -SqlCredential $dbatoolsAzSQLMIcred -Credential $SQLCredentialName

# Remove/drop credential
Remove-DbaCredential -SqlInstance $dbatoolsAzSQLMI -SqlCredential $dbatoolsAzSQLMIcred -Credential $SQLCredentialName