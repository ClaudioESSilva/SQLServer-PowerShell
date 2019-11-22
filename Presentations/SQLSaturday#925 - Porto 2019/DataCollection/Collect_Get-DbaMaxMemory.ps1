#Central Server
Import-Module dbatools -Force

# Set the configurations to
Set-DbaToolsConfig -Name 'psremoting.pssession.usessl' -Value $true
Set-DbaToolsConfig -Name 'psremoting.pssessionoption.includeportinspn' -Value $true

$centralServer = "CentralServer"
$centralDatabase = "dbatools"

$invokeQuerySplatting = @{
    SqlInstance = $centralServer
    Database = $centralDatabase
    Query = "SELECT FQDN FROM vGetInstances ORDER BY 1"
}
$ServerList = Invoke-DbaQuery @invokeQuerySplatting | Select-Object -ExpandProperty FQDN

#region multi-thread
$dt = $ServerList | Start-RSJob -ScriptBlock { Get-DbaMaxMemory -SqlInstance $_ | Select-Object ComputerName, InstanceName, SqlInstance, Total, MaxValue, @{n="Server";e={$_.Server -replace '\[', '' -replace '\]', ''}} } -Throttle 20 | Wait-RsJob | Receive-RsJob
$dt | Add-Member -MemberType NoteProperty -Name CollectionTime -Value $(Get-Date)
$dt | Write-DbaDataTable -SqlInstance $centralServer -Database $centralDatabase -Table "[MaxMemory]" -Schema "dbo" -AutoCreateTable -BatchSize 100

#endregion
