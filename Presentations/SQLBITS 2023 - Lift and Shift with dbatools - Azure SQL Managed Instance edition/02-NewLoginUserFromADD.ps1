<#
    Add Azure Active Directory users as login and/or user to Azure SQL Managed Instance

    NOTE: For this to work you need to have at least dbatools v1.1.137

    Resources:
        - LOGIN: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-login-transact-sql?view=azuresqldb-mi-current&preserve-view=true
        - USER: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-user-transact-sql?view=sql-server-ver16#azure_active_directory_principal
            - Contained user info: https://learn.microsoft.com/en-us/sql/t-sql/statements/create-user-transact-sql?view=sql-server-ver16#azure_active_directory_principal
#>

# Create new login based on Azure AD user
$splatNewAADLogin = @{
    SqlInstance = $dbatoolsAzSQLMI 
    SqlCredential = $dbatoolsAzSQLMIcred
    Login = "AADUser@yourdomain.onmicrosoft.com"
    ExternalProvider = $true 
    DefaultDatabase = "dbatools"
    Verbose = $true
}
New-DbaLogin @splatNewAADLogin


# Create new user based on sql login (Azure Active Directory user) created on previous step
$splatNewDbUser = @{
    SqlInstance = $dbatoolsAzSQLMI 
    SqlCredential = $dbatoolsAzSQLMIcred
    Database = "dbatools"
    Login = "AADUser@yourdomain.onmicrosoft.com"
    Verbose = $true
}
New-DbaDbUser @splatNewDbUser


# Check that user exists, is of type ExternalUser and it's linked to a login with same name
Get-DbaDbUser -SqlInstance $dbatoolsAzSQLMI -SqlCredential $dbatoolsAzSQLMIcred -Database "dbatools" | Where-Object LoginType -eq 'ExternalUser'



# Drop user
$splatRemoveDbUser = @{
    SqlInstance = $dbatoolsAzSQLMI 
    SqlCredential = $dbatoolsAzSQLMIcred
    Database = "dbatools"
    User = "AADUser@yourdomain.onmicrosoft.com"
}
Remove-DbaDbUser @splatRemoveDbUser


# Drop login
$splatRemoveLogin = @{
    SqlInstance = $dbatoolsAzSQLMI 
    SqlCredential = $dbatoolsAzSQLMIcred
    Login = "AADUser@yourdomain.onmicrosoft.com"
}
Remove-DbaLogin @splatRemoveLogin





# Create new database user based on Azure AD User (uses -ExternalProvider - it is a contained user)
$splatNewDbUser = @{
    SqlInstance = $dbatoolsAzSQLMI
    SqlCredential = $dbatoolsAzSQLMIcred
    Database = "dbatools"
    User = "AADUser@yourdomain.onmicrosoft.com"
    ExternalProvider = $true
    Verbose = $true
}
New-DbaDbUser @splatNewDbUser


# Check that user exists, is of type ExternalUser and it's linked to a login with same name
Get-DbaDbUser -SqlInstance $dbatoolsAzSQLMI -SqlCredential $dbatoolsAzSQLMIcred -Database "dbatools" | Where-Object LoginType -eq 'ExternalUser'