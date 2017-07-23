<# VG Portuguese Setup #>
$singleServer = "sql2016"
$sql2016Express = "sql2016\sqlexpress"

#Restore database
Invoke-DbaSqlCmd -ServerInstance sql2016 -Query "IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Rationalised Database Restore Script for dbOrphanUsers') 
	Exec msdb.dbo.sp_start_job 'Rationalised Database Restore Script for dbOrphanUsers'"

#Delete "Rationalised Database Restore Script for dbOrphanUsers" job
Invoke-DbaSqlCmd -ServerInstance sql2016 -Query "
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Rationalised Database Restore Script for dbOrphanUsers') 
    EXEC msdb.dbo.sp_delete_job @job_name=N'Rationalised Database Restore Script for dbOrphanUsers', @delete_unused_schedule=1
"

<# Duplicate Indexes #>
## ADD DUPLICATE INDEXES
$query= @"
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ProdId' AND [object_id] = object_id('Sales.SalesOrderDetail'))
	DROP INDEX [Sales].[SalesOrderDetail].[IX_ProdId]

CREATE NONCLUSTERED INDEX [IX_ProdId] ON [Sales].[SalesOrderDetail]
(
	[ProductID] ASC
)

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesOrderDetail_ProductID__ICarrierTrackingNumber' AND [object_id] = object_id('Sales.SalesOrderDetail'))
	DROP INDEX [Sales].[SalesOrderDetail].[IX_SalesOrderDetail_ProductID__ICarrierTrackingNumber]

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID__ICarrierTrackingNumber] ON [Sales].[SalesOrderDetail]
(
	[ProductID] ASC
)
INCLUDE
(
	[CarrierTrackingNumber]
)

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesOrderDetail_ProductID__FUnitPrice' AND object_id = object_id('Sales.SalesOrderDetail'))
	DROP INDEX [Sales].[SalesOrderDetail].[IX_SalesOrderDetail_ProductID__FUnitPrice]

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID__FUnitPrice] ON [Sales].[SalesOrderDetail]
(
	[ProductID] ASC
)
INCLUDE
(
	[CarrierTrackingNumber]
)
WHERE ([UnitPrice] > 100)


IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_SalesOrderDetail_ProductID__FUnitPrice1000' AND object_id = object_id('Sales.SalesOrderDetail'))
	DROP INDEX [Sales].[SalesOrderDetail].[IX_SalesOrderDetail_ProductID__FUnitPrice1000]

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID__FUnitPrice1000] ON [Sales].[SalesOrderDetail]
(
	[ProductID] ASC
)
WHERE ([UnitPrice] > 1000)
"@
Invoke-DbaSqlCmd -ServerInstance sql2016 -Database AdventureWorks2014 -query $query


<# Orphaned File #>
# Clean up the waste of space on your server by removing orphaned files
<# Orphaned File #>
$Files = Find-DbaOrphanedFile -SqlInstance $sql2016Express
if ($Files.Count -gt 0) {
    $Files.RemoteFileName | Remove-Item
}

$X = 10
While($X -ne 0) {
$DBName = 'Orphan_' + $x
Invoke-DbaSqlcmd -ServerInstance $sql2016Express -Query "CREATE DATABASE $DBName"
$x--
}
Start-Sleep -seconds 5
$srv = Connect-DbaSqlServer -SqlServer $sql2016Express
$srv.Databases.Where{$_.Name -like 'Orphan*'}.ForEach{$srv.DetachDatabase($_.Name,$false,$false)}



<#
Create database
Shrink
Add data to generate a lot of VLFs
#>
Invoke-DbaSqlcmd -ServerInstance $singleServer -Query "IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'AutoGrowth')
BEGIN
	ALTER DATABASE [AutoGrowth] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE IF EXISTS [AutoGrowth]
END
CREATE DATABASE AutoGrowth;
BACKUP DATABASE AutoGrowth TO DISK='NUL'"


$queryConfigureDatabase = @"
DBCC SHRINKFILE (N'AutoGrowth' , 1)
DBCC SHRINKFILE (N'AutoGrowth_log' , 1)
ALTER DATABASE [AutoGrowth] MODIFY FILE ( NAME = N'AutoGrowth', FILEGROWTH = 1024KB )
ALTER DATABASE [AutoGrowth] MODIFY FILE ( NAME = N'AutoGrowth_log', FILEGROWTH = 1024KB )
"@
Invoke-DbaSqlcmd -ServerInstance $singleServer -Database AutoGrowth -Query $queryConfigureDatabase

$queryForceAutoGrowthEvents = @"
DROP TABLE IF EXISTS ToGrow
CREATE TABLE ToGrow
(
    ID BIGINT PRIMARY KEY IDENTITY(1,1)
    ,SomeText VARCHAR(8000) DEFAULT(REPLICATE('A', 80000))
)
DECLARE @Iteration INT = 1
BEGIN TRAN
WHILE (@Iteration < 10000)
	BEGIN
		INSERT INTO ToGrow (SomeText)
		DEFAULT VALUES;

		SET @Iteration += 1;
	END
COMMIT TRAN
"@
0..4 | % {Invoke-DbaSqlcmd -ServerInstance $singleServer -Query $queryForceAutoGrowthEvents -Database AutoGrowth}


$databaseToRefresh = "db1"
Invoke-DbaSqlcmd -ServerInstance $singleServer -Database $db1 -Query "USE [master]
DROP LOGIN [TestOrphan2]
CREATE LOGIN [TestOrphan2] WITH PASSWORD=N'1', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"


Set-DbaMaxMemory -SqlInstance $singleServer -MaxMb 50000

Set-DbaMaxDop -SqlInstance $singleServer -Database DBWithoutOwner -MaxDop 1

Set-DbaMaxDop -SqlInstance sql2016\sqlexpress -MaxDop 1


Invoke-DbaSqlcmd -ServerInstance $singleServer -Database tempdb -Query "DROP TABLE IF EXISTS newTbl;
CREATE TABLE newTbl ( C1 INT ); "

Invoke-DbaSqlcmd -ServerInstance $singleServer -Database master -Query "
/****** Object:  Database [RestoreTimeClean]    Script Date: 7/23/2017 6:36:58 PM ******/
DROP DATABASE IF EXISTS [RestoreTimeClean]

/****** Object:  Database [locations]    Script Date: 7/23/2017 6:36:58 PM ******/
DROP DATABASE IF EXISTS [locations]

/****** Object:  Database [ft1]    Script Date: 7/23/2017 6:36:58 PM ******/
DROP DATABASE IF EXISTS [ft1]

/****** Object:  Database [DBWithoutOwner]    Script Date: 7/23/2017 6:36:58 PM ******/
DROP DATABASE IF EXISTS [DBWithoutOwner]

/****** Object:  Database [dbOrphanUsers]    Script Date: 7/23/2017 6:36:58 PM ******/
DROP DATABASE IF EXISTS [dbOrphanUsers]

/****** Object:  Database [db3]    Script Date: 7/23/2017 6:36:58 PM ******/
DROP DATABASE IF EXISTS [db3]

/****** Object:  Database [db2]    Script Date: 7/23/2017 6:36:58 PM ******/
DROP DATABASE IF EXISTS [db2]

/****** Object:  Database [db1]    Script Date: 7/23/2017 6:36:58 PM ******/
DROP DATABASE IF EXISTS [db1]

/****** Object:  Database [Cube_Query_History]    Script Date: 7/23/2017 6:36:58 PM ******/
DROP DATABASE IF EXISTS [Cube_Query_History]"


Remove-Item -Path "C:\temp\ExportDbaDiagnosticQuery\*.*" -Filter *.csv
Remove-Item -Path "C:\temp\ExecutionPlans\*.*" -Filter *.sqlplan

<# Test-DbaIdentityUsage #>
## Fill the column
#$Query = @"
#INSERT INTO [HumanResources].[Shift]
#([Name],[StartTime],[EndTime],[ModifiedDate])
#VALUES
#( 'Made Up SHift ' + CAST(NEWID() AS nvarchar(MAX)),DATEADD(hour,-4, GetDate()),'07:00:00.0000000',GetDate())
#"@
#$x = 252
#While($x -gt 0) {
#Start-Sleep -Milliseconds 1
#Invoke-DbaSqlCmd -ServerInstance sql2014 -Database AdventureWorks2014 -Query $Query
#$x--
#}
#
## I want to add a row to a table and I ge this error
#$Query = @"
#INSERT INTO [HumanResources].[Shift]
#([Name],[StartTime],[EndTime],[ModifiedDate])
#VALUES
#( 'The Beards Favourite Shift','10:00:00.0000000','11:00:00.0000000',GetDate())
#"@
#
#Invoke-DbaSqlCmd -ServerInstance sql2014 -Database AdventureWorks2014 -Query $Query
#
#Test-DbaIdentityUsage -SqlInstance sql2014 -NoSystemDb -Threshold 70 | ogv