Return 'Cláudio, come on, you are giving a presentation..do not try to run the whole script! :) '

# Check if we have dbatools docker images
docker images "dbatools/*"

# Verify if we have containers setup
docker ps -a

# start container dockersql1
docker start dockersql1

# start container dockersql2
docker start dockersql2


# Setting some variables
$docker1 = "localhost,1433"
$docker2 = "localhost,14333"
$sql2016 = "localhost,1434"

$secureString = ConvertTo-SecureString "dbatools.IO" -AsPlainText -Force
$sqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "sqladmin", $secureString



# Reset for demos

# Reset MaxMemory value for each instance
Set-DbaMaxMemory -SqlInstance $sql2016 -Max 3072
Set-DbaMaxMemory -SqlInstance $docker1 -SqlCredential $sqlCredential -Max 3072
Set-DbaMaxMemory -SqlInstance $docker2 -SqlCredential $sqlCredential -Max 2147483647

# Remove sqladmin login
$splatRemLogin = @{
    SqlInstance = $sql2016
    Login = "sqladmin"
    Force = $true
}

Remove-DbaLogin @splatRemLogin

# Remove-DbaDatabase
Remove-DbaDatabase -SqlInstance $sql2016 -Database "DataTuning" -Confirm:$false

Remove-DbaDatabase -SqlInstance $docker2 -SqlCredential $sqlCredential -Database "Pubs" -Confirm:$false

$query = "
CREATE PROC FindEmail
AS
BEGIN
    SELECT 'someEmail@someDomain.io'
END
"
Invoke-DbaQuery -SqlInstance $docker1 -SqlCredential $sqlCredential -Database Pubs -Query $query

