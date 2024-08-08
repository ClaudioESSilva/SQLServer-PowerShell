/********************************************************************************
	DEMO: Adding column that allow NULLs (no default value)

	NOTE: This was always an "online" operation even before SQL Server 2012
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
	Id			int			NOT NULL IDENTITY(1,1) PRIMARY KEY,
	FirstName	varchar(30) NOT NULL,
	DoB			date		NOT NULL
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
	INSERT INTO dbo.Client (FirstName, DoB)
	SELECT TOP (50000) 'Charles', '1981-04-17'
	  FROM Nums
GO

/*
	Check the contents
*/
SELECT * 
  FROM dbo.Client
GO

/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO

/*
	Let's clean any unneeded unused space
*/
ALTER TABLE dbo.Client REBUILD
GO

/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO



/*
	This (undocumented) command list all the pages that are allocated to an index. 
*/ 
DBCC IND ('XRaying', 'dbo.Client', 1);
GO

/*
	A newer way (DMF) with a bit more information (also undocumented)
*/
SELECT *
  FROM sys.dm_db_database_page_allocations(DB_ID('XRaying'), OBJECT_ID(N'dbo.Client'), NULL, NULL, N'DETAILED')
GO


/*
	Explain the difference between the number of rows returned

	DBCC IND: 
		returns 170
			- 168 (DATA) pages = 1344 KB
			- 2 'index_size' pages:
				- 1 IAM_PAGE that is shown in the index_size even that technically isn’t an index
				- 1 page belonging to the CLUSTERED INDEX

	sys.dm_db_database_page_allocations:
		returns 177
			- 7 pages assigned but still unused - Link to the unused space. 7 pages x 8 KB = 56 KB.
*/


/*
	Check the content of a page

	TF 3604 - Make the output go to the console (instead of error log)

	printopt = 3 means we will get the page header plus detailed per-row interpretation
*/
DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 521344, 3);
GO



/************************************************
*************************************************
	Copy the results to a new window 
*************************************************
************************************************/










/*
	Adding a new column that allows NULL
	Quick! Right?
*/
ALTER TABLE dbo.Client
  ADD JobTitle VARCHAR(50) NULL
GO

/*
	Proving the column is there
*/
SELECT *
  FROM dbo.Client
GO

/*
	Check the content of a page
*/
DBCC PAGE (N'XRaying', 1, 521344, 3);
GO

/*
	Compare with previous results!

	Hint: check "m_lsn"
		- This is the Log Sequence Number of the last log record that changed the page.
	Source: https://www.sqlskills.com/blogs/paul/inside-the-storage-engine-anatomy-of-a-page/

	This shows that this page wasn't updated (written)!

	Also, you can see that the Offset for the new column is 0x0
*/




/*
	But then, how the engine knows that the column exists?
	Check the metadata!
*/
SELECT sip.*,
		sipc.*
  FROM sys.system_internals_partitions AS sip
	JOIN sys.system_internals_partition_columns AS sipc
	  ON sip.partition_id = sipc.partition_id
 WHERE sip.object_id = OBJECT_ID('dbo.Client')
GO

/*
	Just few metadata for now
*/
SELECT 
	p.index_id, 
	p.partition_number, 
	pc.leaf_null_bit,
	coalesce(cx.name, c.name) as column_name,
	pc.partition_column_id,
	pc.modified_count,
	pc.is_nullable,
	pc.default_value
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
	 AND p.index_id in (0,1)
	 AND pc.partition_column_id = cx.column_id
 WHERE p.object_id = object_id('Client')
ORDER BY index_id, partition_number;
GO


/*
	UPDATE the JobTitle for one record
*/
UPDATE dbo.Client
   SET JobTitle = 'Developer'
 WHERE Id = 1
GO

/*
	What changed on the page?
*/
DBCC PAGE (N'XRaying', 1, 521344, 3);
GO

/*
	1. m_lsn <- Changed
	2. We can see the actual value on the record. (now with an offset too)
*/


/*
	However you may say:
	"Adding the column was so fast because the table just have 50000 records"
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
	INSERT INTO dbo.Client (FirstName, DoB, JobTitle)
	SELECT TOP (1000000) 'Charles', '1981-04-17', 'Chef'
	  FROM Nums
GO


/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO

/*
	Adding a new column that allows NULL
	Quick! Right?
*/
ALTER TABLE dbo.Client
  ADD SomeNumber INT NULL
GO
