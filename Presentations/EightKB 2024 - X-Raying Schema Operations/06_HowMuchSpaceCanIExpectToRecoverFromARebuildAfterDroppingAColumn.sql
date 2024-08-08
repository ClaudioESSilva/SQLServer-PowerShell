/********************************************************************************
	DEMO: How much Space can I expect to recover from a rebuild after dropping a column?

	Blog post: https://claudioessilva.eu/2024/08/05/How-much-space-can-I-expect-to-recover-from-a-rebuild-after-dropping-a-column/
********************************************************************************/
/* Just don't run everything */
THROW 81920, 'Hey! Just don''t run everything. ??', 1
GO

USE XRaying
GO

DROP TABLE IF EXISTS dbo.Client
GO

/* 
	Create a table 
*/
CREATE TABLE dbo.Client
(
  Id		int NOT NULL identity(1,1),
  FirstName varchar(50),
  DoB		datetime
)
GO

/*
	Insert some records	
*/
;WITH
    L0 AS ( SELECT 1 AS c
            FROM (VALUES(1),(1),(1),(1),(1),(1),(1),(1),
                        (1),(1),(1),(1),(1),(1),(1),(1)) AS D(c) ),
    L1 AS ( SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B ),
    L2 AS ( SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B ),
    L3 AS ( SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B ),
    Nums AS ( SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rownum
              FROM L3
      )
  INSERT INTO dbo.Client ([FirstName], DoB)
  SELECT TOP (50000) 'Alex', '1900-01-01'
    FROM Nums
GO


/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO

/*
	Checking the columns that belong to the sys.system_internals_partition_columns system view
*/
EXEC sp_help 'sys.system_internals_partition_columns'
GO


/*
	Let's do some math
*/
SELECT
        OBJECT_NAME(p.object_id) AS table_name,
        COALESCE(cx.[name], c.[name]) as column_name,
        pc.partition_column_id,
        pc.is_dropped,
        /*
            New columns added
        */
		pc.max_length,
        p.[rows],
        pc.max_length * p.[rows] AS total_bytes,
        (pc.max_length * p.[rows]) / 1000 AS total_kb,
        (pc.max_length * p.[rows]) / 1000 / 8 AS total_pages
  FROM sys.system_internals_partitions p
    JOIN sys.system_internals_partition_columns pc
      ON p.partition_id = pc.partition_id
    LEFT JOIN sys.index_columns ic
      ON p.object_id = ic.object_id
     AND ic.index_id = p.index_id
     AND ic.index_column_id = pc.partition_column_id
    LEFT JOIN sys.columns c
      ON p.object_id = c.object_id
     AND ic.column_id = c.column_id
    LEFT JOIN sys.columns cx
      ON p.object_id = cx.object_id  
     AND pc.partition_column_id = cx.column_id
    CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), p.object_id, p.index_id, DEFAULT, 'LIMITED') AS ddips
 WHERE p.object_id = object_id('dbo.Client')
   AND p.index_id IN (0, 1)
GO





/*
	Results:
		table_name	column_name	partition_column_id	is_dropped	max_length	rows	total_bytes	total_kb	total_pages
		Client		Id			1					0			4			50000	200000		200			25
		Client		FirstName	2					0			50			50000	2500000		2500		312
		Client		DoB			3					0			8			50000	400000		400			50
*/


/*
	Let's drop our DoB column
*/
ALTER TABLE Client
 DROP COLUMN DoB
GO


/*
	Doing the math of the dropped column
*/
SELECT
        OBJECT_NAME(p.object_id) AS table_name,
        COALESCE(cx.[name], c.[name]) as column_name,
        pc.partition_column_id,
        pc.is_dropped,
        /*
            New columns added
        */
		pc.max_length,
        p.[rows],
        pc.max_length * p.[rows] AS total_bytes,
        (pc.max_length * p.[rows]) / 1000 AS total_kb,
        (pc.max_length * p.[rows]) / 1000 / 8 AS total_pages
  FROM sys.system_internals_partitions p
    JOIN sys.system_internals_partition_columns pc
      ON p.partition_id = pc.partition_id
    LEFT JOIN sys.index_columns ic
      ON p.object_id = ic.object_id
     AND ic.index_id = p.index_id
     AND ic.index_column_id = pc.partition_column_id
    LEFT JOIN sys.columns c
      ON p.object_id = c.object_id
     AND ic.column_id = c.column_id
    LEFT JOIN sys.columns cx
      ON p.object_id = cx.object_id  
     AND pc.partition_column_id = cx.column_id
    CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), p.object_id, p.index_id, DEFAULT, 'LIMITED') AS ddips
 WHERE p.object_id = object_id('dbo.Client')
   AND p.index_id IN (0, 1)
   AND is_dropped = 1


/*
	To keep the math going, we will need to know how many pages our tables has.

	Using dynamic management function (DMF) 'sys.dm_db_index_physical_stats'
	we can get the 'page_count'
*/
SELECT
        OBJECT_NAME(p.object_id) AS table_name,
        COALESCE(cx.[name], c.[name]) as column_name,
        pc.partition_column_id,
        pc.is_dropped,
        pc.max_length,
        p.[rows],
        pc.max_length * p.[rows] AS total_bytes,
        (pc.max_length * p.[rows]) / 1000 AS total_kb,
        (pc.max_length * p.[rows]) / 1000 / 8 AS total_pages,
        
		/* New column added */  
		ddips.page_count AS current_page_count 
  FROM sys.system_internals_partitions p
    JOIN sys.system_internals_partition_columns pc
      ON p.partition_id = pc.partition_id
    LEFT JOIN sys.index_columns ic
      ON p.object_id = ic.object_id
     AND ic.index_id = p.index_id
     AND ic.index_column_id = pc.partition_column_id
    LEFT JOIN sys.columns c
      ON p.object_id = c.object_id
     AND ic.column_id = c.column_id
    LEFT JOIN sys.columns cx
      ON p.object_id = cx.object_id  
     AND pc.partition_column_id = cx.column_id
    CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), p.object_id, p.index_id, DEFAULT, 'LIMITED') AS ddips
 WHERE p.object_id = object_id('dbo.Client')
   AND p.index_id IN (0, 1)
   AND is_dropped = 1


/*
	Final math
*/
SELECT
        OBJECT_NAME(p.object_id) AS table_name,
        COALESCE(cx.[name], c.[name]) as column_name,
        pc.partition_column_id,
        pc.is_dropped,
        pc.max_length,
        p.[rows],
        pc.max_length * p.[rows] AS total_bytes,
        (pc.max_length * p.[rows]) / 1000 AS total_kb,
        (pc.max_length * p.[rows]) / 1000 / 8 AS total_pages,
        ddips.page_count AS current_page_count,
        /*
            New columns added
        */
		ddips.page_count - (pc.max_length * p.[rows] / 1000 / 8) AS new_page_count,
        ddips.page_count * 8 AS current_data_size_kb,
        (ddips.page_count - (pc.max_length * p.[rows] / 1000 / 8)) * 8 AS new_data_size_kb
  FROM sys.system_internals_partitions p
    JOIN sys.system_internals_partition_columns pc
      ON p.partition_id = pc.partition_id
    LEFT JOIN sys.index_columns ic
      ON p.object_id = ic.object_id
     AND ic.index_id = p.index_id
     AND ic.index_column_id = pc.partition_column_id
    LEFT JOIN sys.columns c
      ON p.object_id = c.object_id
     AND ic.column_id = c.column_id
    LEFT JOIN sys.columns cx
      ON p.object_id = cx.object_id  
     AND pc.partition_column_id = cx.column_id
    CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), p.object_id, p.index_id, DEFAULT, 'LIMITED') AS ddips
 WHERE p.object_id = object_id('dbo.Client')
   AND p.index_id IN (0, 1)
   AND is_dropped = 1
GO


/*
	Does the math adds up?

	First let's clear the dropped column and tidy up things
*/
ALTER TABLE dbo.Client REBUILD
GO

SELECT
        OBJECT_NAME(p.object_id) AS table_name,
        COALESCE(cx.[name], c.[name]) as column_name,
        pc.partition_column_id,
        pc.is_dropped,
        pc.max_length,
        p.[rows],
        ddips.page_count AS current_page_count
  FROM sys.system_internals_partitions p
    JOIN sys.system_internals_partition_columns pc
      ON p.partition_id = pc.partition_id
    LEFT JOIN sys.index_columns ic
      ON p.object_id = ic.object_id
     AND ic.index_id = p.index_id
     AND ic.index_column_id = pc.partition_column_id
    LEFT JOIN sys.columns c
      ON p.object_id = c.object_id
     AND ic.column_id = c.column_id
    LEFT JOIN sys.columns cx
      ON p.object_id = cx.object_id  
     AND pc.partition_column_id = cx.column_id
    CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), p.object_id, p.index_id, DEFAULT, 'LIMITED') AS ddips
 WHERE p.object_id = object_id('dbo.Client')
   AND p.index_id IN (0, 1)
GO

/*
	Why can this be interesting?
		- Lot's of space you have urgency to recover?
		- Think about the maintenance window? 


	Caveats:
		- Compression
*/