Return 'Cláudio, come on, you are giving a presentation..do not try to run the whole script! :) '

# Logins

# Create new login
$splatNewLogin = @{
    SqlInstance = $sql2016
    Login = "sqladmin"
    SecurePassword = ConvertTo-SecureString "dbatools.IO" -AsPlainText -Force
}

New-DbaLogin @splatNewLogin


# Add login to sysadmin role
$splatSrvRoleMember = @{
    SqlInstance = $sql2016
    Login = "sqladmin"
    ServerRole = "SecurityAdmin"
    Confirm = $false
}

Add-DbaServerRoleMember @splatSrvRoleMember

# Confirm that Login was added to server role
Get-DbaServerRoleMember -SqlInstance $sql2016 -ServerRole "SecurityAdmin"


# Create a database
$splatNewDatabase = @{
    SqlInstance = $sql2016
    Name = "DataTuning"
    Owner = "sa"
    RecoveryModel = "Simple"
}
New-DbaDatabase @splatNewDatabase


# Add user to database mapped to login
$splatAddUser = @{
    SqlInstance = $sql2016
    Login = "sqladmin"
    Database = "DataTuning"
}
New-DbaDbUser @splatAddUser




# Copy login between instances

# Exists on source
Get-DbaLogin -SqlInstance $docker1 -SqlCredential $sqlCredential -Login Webuser

# Do not exists on destination
Get-DbaLogin -SqlInstance $docker2 -SqlCredential $sqlCredential -Login Webuser

$splatCopyLogin = @{
    Source = $docker1
    SourceSqlCredential = $sqlCredential
    Destination = $docker2
    DestinationSqlCredential = $sqlCredential
    Login = "WebUser"
    Force = $true
}

Copy-DbaLogin @splatCopyLogin


Remove-DbaLogin -SqlInstance $docker2 -SqlCredential $sqlCredential -Login Webuser
