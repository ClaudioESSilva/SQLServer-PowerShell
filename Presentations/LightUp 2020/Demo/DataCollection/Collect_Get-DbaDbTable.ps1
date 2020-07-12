#Central Server
Import-Module dbatools -Force

# Set the configurations to
Set-DbaToolsConfig -Name 'psremoting.pssession.usessl' -Value $true
Set-DbaToolsConfig -Name 'psremoting.pssessionoption.includeportinspn' -Value $true

$centralServer = "localhost"
$centralDatabase = "dbatools2"
$throttle = 10

$invokeQuerySplatting = @{
    SqlInstance = $centralServer
    Database = $centralDatabase
    Query = "SELECT hostname FROM vGetInstances ORDER BY 1"
}
$ServerList = Invoke-DbaQuery @invokeQuerySplatting | Select-Object -ExpandProperty hostname

$sb = {
    param (
        $pcentralServer
        ,$pcentralDatabase
    )

    $dt = Get-DbaDbTable -SqlInstance $_ -ExcludeDatabase master, msdb, model, tempdb |
        Select-Object ComputerName, InstanceName, SqlInstance, Database, Schema, Name, IndexSpaceUsed, DataSpaceUsed, RowCount, HasClusteredIndex, IsFileTable, IsMemoryOptimized, IsPartitioned, FullTextIndex, ChangeTrackingEnabled
    $dt | Add-Member -MemberType NoteProperty -Name CollectionTime -Value $(Get-Date)
    $dt | Write-DbaDataTable -SqlInstance $pcentralServer -Database $pcentralDatabase -Table "[DatabaseTable]" -Schema "dbo" -AutoCreateTable -BatchSize 10000
}

#region multi-thread
$ServerList | Start-RSJob -ScriptBlock $sb -Throttle $throttle -ArgumentList $centralServer, $centralDatabase | Wait-RsJob | Receive-RsJob

#Clean up
Get-RsJob | Remove-RsJob

#endregion
