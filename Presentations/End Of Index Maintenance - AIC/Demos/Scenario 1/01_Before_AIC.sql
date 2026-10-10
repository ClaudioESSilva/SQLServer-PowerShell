THROW 811920, 'Hey! Just don''t run everything!', 1
GO

/*
    CREATE TABLE that will have up to 2 records per data page
*/
DROP TABLE IF EXISTS dbo.aic_demo_2perpage;
GO

/* Create the test table — GUID clustered key, fixed-width rows */
CREATE TABLE dbo.aic_demo_2perpage
(
    id          INT IDENTITY(1,1)   NOT NULL,
    val         INT                 NOT NULL DEFAULT 1,
    comments    CHAR(3800)          NOT NULL DEFAULT REPLICATE('x', 3800),
    CONSTRAINT pk_aic_demo_2perpage PRIMARY KEY CLUSTERED (id)
);
GO

/*
    Check some index properties
*/
SELECT i.name AS index_name,
       ps.used_page_count,
       ps.reserved_page_count,
       CAST(ps.reserved_page_count / 128.0 AS decimal(7,2)) AS index_total_size_mb,
       i.fill_factor,
       CAST(ips.avg_page_space_used_in_percent AS decimal(5,2)) AS density_pct,
       ips.page_count AS leaf_page_count,
       ips.record_count,
       CAST(ips.avg_fragmentation_in_percent AS decimal(5,2)) AS frag_pct,
       pvs.persistent_version_store_size_kb AS pvs_kb
FROM sys.dm_db_partition_stats AS ps
    INNER JOIN sys.indexes AS i
       ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.aic_demo_2perpage'), 1, 1, 'DETAILED') AS ips
       ON i.object_id = ips.object_id
      AND i.index_id = ips.index_id
    CROSS JOIN sys.dm_tran_persistent_version_store_stats AS pvs
WHERE ps.object_id = OBJECT_ID(N'dbo.aic_demo_2perpage')
  AND ips.index_level = 0
  AND pvs.database_id = DB_ID();
GO

/* 
    Insert 1 row 
*/
INSERT INTO dbo.aic_demo_2perpage (val)
SELECT v.value
FROM GENERATE_SERIES(1, 1) AS v;
GO

/*
    Check some index properties
*/
SELECT i.name AS index_name,
       ps.used_page_count,
       ps.reserved_page_count,
       CAST(ps.reserved_page_count / 128.0 AS decimal(7,2)) AS index_total_size_mb,
       i.fill_factor,
       CAST(ips.avg_page_space_used_in_percent AS decimal(5,2)) AS density_pct,
       ips.page_count AS leaf_page_count,
       ips.record_count,
       CAST(ips.avg_fragmentation_in_percent AS decimal(5,2)) AS frag_pct,
       pvs.persistent_version_store_size_kb AS pvs_kb
FROM sys.dm_db_partition_stats AS ps
    INNER JOIN sys.indexes AS i
       ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.aic_demo_2perpage'), 1, 1, 'DETAILED') AS ips
       ON i.object_id = ips.object_id
      AND i.index_id = ips.index_id
    CROSS JOIN sys.dm_tran_persistent_version_store_stats AS pvs
WHERE ps.object_id = OBJECT_ID(N'dbo.aic_demo_2perpage')
  AND ips.index_level = 0
  AND pvs.database_id = DB_ID();
GO

/* 
    TRUNCATE and insert 1,000 rows
*/
TRUNCATE TABLE dbo.aic_demo_2perpage
GO
INSERT INTO dbo.aic_demo_2perpage (val)
SELECT v.value
FROM GENERATE_SERIES(1, 1000) AS v;
GO


/*
    Check some index properties
*/
SELECT i.name AS index_name,
       ps.used_page_count,
       ps.reserved_page_count,
       CAST(ps.reserved_page_count / 128.0 AS decimal(7,2)) AS index_total_size_mb,
       i.fill_factor,
       CAST(ips.avg_page_space_used_in_percent AS decimal(5,2)) AS density_pct,
       ips.page_count AS leaf_page_count,
       ips.record_count,
       CAST(ips.avg_fragmentation_in_percent AS decimal(5,2)) AS frag_pct,
       pvs.persistent_version_store_size_kb AS pvs_kb
FROM sys.dm_db_partition_stats AS ps
    INNER JOIN sys.indexes AS i
       ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.aic_demo_2perpage'), 1, 1, 'DETAILED') AS ips
       ON i.object_id = ips.object_id
      AND i.index_id = ips.index_id
    CROSS JOIN sys.dm_tran_persistent_version_store_stats AS pvs
WHERE ps.object_id = OBJECT_ID(N'dbo.aic_demo_2perpage')
  AND ips.index_level = 0
  AND pvs.database_id = DB_ID();
GO


/* 
    Confirm current status of AIC
*/
SELECT name AS database_name,
       IIF(is_automatic_index_compaction_on = 1, 'ON', 'OFF') AS aic_status
FROM sys.databases
WHERE database_id = DB_ID();








/*
    DELETE half of the data
*/
DELETE dbo.aic_demo_2perpage
WHERE id % 2 = 0
GO


/*
    Check some index properties

    Notice that the density_pct is < 50%.
    NOTE: It may need a couple of seconds to show. Retry.
*/
SELECT i.name AS index_name,
       ps.used_page_count,
       ps.reserved_page_count,
       CAST(ps.reserved_page_count / 128.0 AS decimal(7,2)) AS index_total_size_mb,
       i.fill_factor,
       CAST(ips.avg_page_space_used_in_percent AS decimal(5,2)) AS density_pct,
       ips.page_count AS leaf_page_count,
       ips.record_count,
       CAST(ips.avg_fragmentation_in_percent AS decimal(5,2)) AS frag_pct,
       pvs.persistent_version_store_size_kb AS pvs_kb
FROM sys.dm_db_partition_stats AS ps
    INNER JOIN sys.indexes AS i
       ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.aic_demo_2perpage'), 1, 1, 'DETAILED') AS ips
       ON i.object_id = ips.object_id
      AND i.index_id = ips.index_id
    CROSS JOIN sys.dm_tran_persistent_version_store_stats AS pvs
WHERE ps.object_id = OBJECT_ID(N'dbo.aic_demo_2perpage')
  AND ips.index_level = 0
  AND pvs.database_id = DB_ID();
GO


/*
    Check the number of logical reads
*/
SET STATISTICS TIME, IO ON;

SELECT COUNT_BIG(*) AS row_count
FROM dbo.aic_demo_2perpage
OPTION (MAXDOP 1);

SET STATISTICS TIME, IO OFF;


/*
    Run the next 3 queries in one go

    Check some index properties
*/
SELECT i.name AS index_name,
       ps.used_page_count,
       ps.reserved_page_count,
       CAST(ps.reserved_page_count / 128.0 AS decimal(7,2)) AS index_total_size_mb,
       i.fill_factor,
       CAST(ips.avg_page_space_used_in_percent AS decimal(5,2)) AS density_pct,
       ips.page_count AS leaf_page_count,
       ips.record_count,
       CAST(ips.avg_fragmentation_in_percent AS decimal(5,2)) AS frag_pct,
       pvs.persistent_version_store_size_kb AS pvs_kb
FROM sys.dm_db_partition_stats AS ps
    INNER JOIN sys.indexes AS i
       ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.aic_demo_2perpage'), 1, 1, 'DETAILED') AS ips
       ON i.object_id = ips.object_id
      AND i.index_id = ips.index_id
    CROSS JOIN sys.dm_tran_persistent_version_store_stats AS pvs
WHERE ps.object_id = OBJECT_ID(N'dbo.aic_demo_2perpage')
  AND ips.index_level = 0
  AND pvs.database_id = DB_ID();
GO


/*
        Run the REORGANIZE on the index to compact the records and release 
    the empty data pages
*/
ALTER INDEX pk_aic_demo_2perpage ON dbo.aic_demo_2perpage REORGANIZE
GO


/*
    Check some index properties
*/
SELECT i.name AS index_name,
       ps.used_page_count,
       ps.reserved_page_count,
       CAST(ps.reserved_page_count / 128.0 AS decimal(7,2)) AS index_total_size_mb,
       i.fill_factor,
       CAST(ips.avg_page_space_used_in_percent AS decimal(5,2)) AS density_pct,
       ips.page_count AS leaf_page_count,
       ips.record_count,
       CAST(ips.avg_fragmentation_in_percent AS decimal(5,2)) AS frag_pct,
       pvs.persistent_version_store_size_kb AS pvs_kb
FROM sys.dm_db_partition_stats AS ps
    INNER JOIN sys.indexes AS i
       ON ps.object_id = i.object_id AND ps.index_id = i.index_id
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.aic_demo_2perpage'), 1, 1, 'DETAILED') AS ips
       ON i.object_id = ips.object_id
      AND i.index_id = ips.index_id
    CROSS JOIN sys.dm_tran_persistent_version_store_stats AS pvs
WHERE ps.object_id = OBJECT_ID(N'dbo.aic_demo_2perpage')
  AND ips.index_level = 0
  AND pvs.database_id = DB_ID();
GO


/*
    Check the number of logical reads
    
    Remember that before it was: 502
*/
SET STATISTICS TIME, IO ON;

SELECT COUNT_BIG(*) AS row_count
FROM dbo.aic_demo_2perpage
OPTION (MAXDOP 1);

SET STATISTICS TIME, IO OFF;


/*
    Conclusion:
        - We need to run some maintenace tasks to compact the index and reclaim the space 
            - This normally comes in a nightly (or other recurrence) job (like Ola) that will deal with it.
        - Rebuild also works (depending on the edition it can be done "ONLINE")
*/