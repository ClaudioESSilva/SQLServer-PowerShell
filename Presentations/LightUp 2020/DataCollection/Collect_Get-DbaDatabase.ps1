#Central Server
Import-Module dbatools -Force

# Set the configurations to
Set-DbaToolsConfig -Name 'psremoting.pssession.usessl' -Value $true
Set-DbaToolsConfig -Name 'psremoting.pssessionoption.includeportinspn' -Value $true

$centralServer = "CentralServer"
$centralDatabase = "dbatools"
$throttle = 10

$invokeQuerySplatting = @{
    SqlInstance = $centralServer
    Database = $centralDatabase
    Query = "SELECT FQDN FROM vGetInstances WHERE DOMAIN LIKE '$env:UserDomain%' ORDER BY 1"
}
$ServerList = Invoke-DbaQuery @invokeQuerySplatting | Select-Object -ExpandProperty FQDN

$sb = {
    param (
        $pcentralServer
        ,$pcentralDatabase
    )

    $dt = Get-DbaDatabase -SqlInstance $_ | Select-Object ComputerName `
        , InstanceName `
        , SqlInstance `
        , SizeMB `
        , Compatibility `
        , LastFullBackup `
        , LastDiffBackup `
        , LastLogBackup `
        , Parent `
        , ActiveConnections `
        , Collation                   `
        , CompatibilityLevel          `
        , CreateDate                  `
        , DatabaseGUID                `
        , DataSpaceUsage              `
        , DefaultFileGroup            `
        , DelayedDurability           `
        , EncryptionEnabled           `
        , HasMemoryOptimizedObjects   `
        , ID                          `
        , IndexSpaceUsage             `
        , IsAccessible                `
        , IsDatabaseSnapshot          `
        , Owner                     `
        , PageVerify                  `
        , RecoveryModel               `
        , SpaceAvailable              `
        , Status                    `
        , TargetRecoveryTime          `
        , Trustworthy               `
        , UserAccess                  `
        , Version                   `
        , DatabaseEngineType          `
        , DatabaseEngineEdition       `
        , Name `

    $dt | Add-Member -MemberType NoteProperty -Name CollectionTime -Value $(Get-Date)
    $dt | Write-DbaDataTable -SqlInstance $pcentralServer -Database $pcentralDatabase -Table "[Database]" -Schema "dbo" -AutoCreateTable
}

#region multi-thread
$ServerList | Start-RSJob -ScriptBlock $sb -Throttle $throttle -ArgumentList $centralServer, $centralDatabase | Wait-RsJob | Receive-RsJob

#Clean up
Get-RsJob | Remove-RsJob

#endregion




