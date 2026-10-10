/*
    This scripts uses the table creation from Bob Ward.
    Source: https://github.com/microsoft/bobsql/tree/90fb8be01973db901939f5635bd34d789ecd4ada/demos/auto_index_compaction

    Creates a 250K-row table with a GUID clustered key and fixed-width rows.
    
    - GUID CI key distributes rows randomly across pages.
    - char(100) keeps row width constant (~130 bytes/row, ~59 rows/page).
    - REBUILD after insert gives 99.8% page density baseline.
*/

/* Confirm current status */
SELECT name AS database_name,
       IIF(is_automatic_index_compaction_on = 1, 'ON', 'OFF') AS aic_status
FROM sys.databases
WHERE database_id = DB_ID();

/* Enable automatic index compaction */
ALTER DATABASE CURRENT SET AUTOMATIC_INDEX_COMPACTION = ON;
GO

/* Confirm it's enabled */
SELECT name AS database_name,
       IIF(is_automatic_index_compaction_on = 1, 'ON', 'OFF') AS aic_status
FROM sys.databases
WHERE database_id = DB_ID();



/* Reset to clean state */
DROP TABLE IF EXISTS dbo.aic_demo;
GO

/* Create the test table — GUID clustered key, fixed-width rows */
CREATE TABLE dbo.aic_demo
(
    id uniqueidentifier NOT NULL DEFAULT NEWID(),
    dt datetime2 NOT NULL DEFAULT SYSDATETIME(),
    val int NOT NULL DEFAULT 0,
    s char(100) NOT NULL DEFAULT REPLICATE('x', 100),
    CONSTRAINT pk_aic_demo PRIMARY KEY CLUSTERED (id)
);
GO

/* Insert 1,000,000 rows */
INSERT INTO dbo.aic_demo (id, val)
SELECT NEWID(), v.value
FROM GENERATE_SERIES(1, 250000) AS v;
GO

/* Rebuild to get optimal density after GUID-fragmented insert */
ALTER INDEX pk_aic_demo ON dbo.aic_demo REBUILD;
GO
