#Central Server
#Import-Module dbatools -Force

# Set the configurations to
#et-DbaToolsConfig -Name 'psremoting.pssession.usessl' -Value $true
#et-DbaToolsConfig -Name 'psremoting.pssessionoption.includeportinspn' -Value $true

$centralServer = "localhost"
$centralDatabase = "dbatools2"
$throttle = 10

#$invokeQuerySplatting = @{
#    SqlInstance = $centralServer
#    Database = $centralDatabase
#    Query = "SELECT FQDN FROM vGetInstances WHERE DOMAIN LIKE '$env:UserDomain%' ORDER BY 1"
#}
#$ServerList = Invoke-DbaQuery @invokeQuerySplatting | Select-Object -ExpandProperty FQDN

$ServerList = "localhost"

$sb = {
    param (
        $pcentralServer
        ,$pcentralDatabase
    )
    $dt = Get-DbaComputerSystem -ComputerName $_
    $dt | Add-Member -MemberType NoteProperty -Name CollectionTime -Value $(Get-Date)
    $dt | Write-DbaDataTable -SqlInstance $pcentralServer -Database $pcentralDatabase -Table "[ComputerSystem]" -Schema "dbo" -BatchSize 100 -AutoCreateTable
}

#region ComputerSystem ("multi-thread")
$ServerList | Start-RSJob -ScriptBlock $sb -Throttle $throttle -ArgumentList $centralServer, $centralDatabase | Wait-RsJob | Receive-RsJob

#Clean up
Get-RsJob | Remove-RsJob

#endregion
