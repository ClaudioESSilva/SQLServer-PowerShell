#Build server list
$serverList = "sql2000","sql2005","sql2008","sql2012","sql2014", "sqlcluster", "sql2016a","sql2016\SQLEXPRESS","sql2016\STANDARDRTM"

Write-Host "Hey! you are demoing, right? Please select a block of code!" -ForegroundColor Red -BackgroundColor Black
return

<#
    MaxMemory
#>
$serverList = "sql2008","sql2014","sql2016\SQLEXPRESS","sql2016\STANDARDRTM"
Set-DbaMaxMemory -SqlServer $serverList 

<#
   MaxDop
#>
$serverList = "sql2012","sql2014","sql2016\STANDARDRTM"
Set-DbaMaxDop -SqlServer $serverList


<#
    Get DbaLastBackup Backup-DbaDatabase
#>
#To measure elapsed time
$start = [System.Diagnostics.Stopwatch]::StartNew()

Get-DbaDatabase -SqlInstance sql2005 | Where-Object LastFullBackup -lt (Get-Date).AddDays(1) | Format-Table -AutoSize

Get-DbaDatabase -SqlInstance sql2005 | Where-Object LastFullBackup -lt (Get-Date).AddDays(1) | ForEach-Object {Backup-DbaDatabase -SqlInstance $_.SqlInstance -Databases $_.Name}
Get-DbaDatabase -SqlInstance sql2016a | Where-Object LastFullBackup -lt (Get-Date).AddDays(-1) | Backup-DbaDatabase
Get-DbaDatabase -SqlInstance sql2016\STANDARDRTM | Where-Object LastFullBackup -lt (Get-Date).AddDays(-1) | Backup-DbaDatabase

$start.elapsed

<#
    Test DbaFullRecoveryModel | Backup-DbaDatabase
#>
Test-DbaFullRecoveryModel -SqlServer sql2008 | Where ActualRecoveryModel -ne "FULL" | Format-Table -AutoSize

Test-DbaFullRecoveryModel -SqlServer sql2008 | Where ActualRecoveryModel -ne "FULL" | ForEach-Object {Backup-DbaDatabase -SqlInstance $_.Server -Databases $_.Database}


<#
    Get DbaLastGoodCheckDb

    Change databases
#>
Invoke-Sqlcmd2 -ServerInstance sql2012 -Query "DBCC CHECKDB('Northwind') WITH NO_INFOMSGS"
Invoke-Sqlcmd2 -ServerInstance sql2014 -Query "DBCC CHECKDB('AdventureWorks2014') WITH NO_INFOMSGS"
Invoke-Sqlcmd2 -ServerInstance sql2016 -Query "DBCC CHECKDB('dbOrphanUsers') WITH NO_INFOMSGS"


<#
    Test DbaVirtualLogFile
#>
Expand-SqlTLogResponsibly -SqlServer sql2014 -Databases Cube_Query_History -ShrinkLogFile -ShrinkSizeMB 1 -TargetLogSizeMB 256 -Verbose


<#
    TempDB
#>
Set-SqlTempDbConfiguration -SqlServer sql2014 -datafilecount 4 -datafilesizemb 80


<#
   Set database owner 
#>
Set-DbaDatabaseOwner -SqlServer sql2005 -Databases dumpsterfire4
Set-DbaDatabaseOwner -SqlServer sql2012 -Databases db1,db2,db3

<#
   Set jobs owner 
#>
Set-DbaJobOwner -SqlServer sql2005 -Jobs 'IndexOptimize - User'


<#
    OptimizeForAdHoc
#>
Invoke-Sqlcmd2 -ServerInstance sql2012 -Query "EXEC sys.sp_configure N'optimize for ad hoc workloads', N'1'"
Invoke-Sqlcmd2 -ServerInstance sql2012 -Query "RECONFIGURE WITH OVERRIDE"


Invoke-Sqlcmd2 -ServerInstance sql2008 -Query "EXEC sys.sp_configure N'optimize for ad hoc workloads', N'1'"
Invoke-Sqlcmd2 -ServerInstance sql2008 -Query "RECONFIGURE WITH OVERRIDE"

<#
    Test PowerPlan configuration
#>
$serverList = "sql2014","sql2016a","sql2016"
Set-DbaPowerPlan -ComputerName $serverList


<#
    Test DbaDiskAllocation
#>
#Well, talk with your sysadmin :-)


<#
    Test DbaDiskAlignment
#>
#Same here



