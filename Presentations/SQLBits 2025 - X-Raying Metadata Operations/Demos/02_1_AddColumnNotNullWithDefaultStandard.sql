/********************************************************************************
	DEMO: Adding column that DOESN'T allow NULLs (with a default value)

	Spoiler: This is still an "online" operation when using Enterprise edition
			 With Standard is an offline and writing operation
********************************************************************************/
/* Just don't run everything */
RAISERROR('Hey! Just don''t run everything. 😁', 20, 1) WITH LOG, NOWAIT;
GO

/*
	Connect to an instance running Standard edition
	Show SQL Server edition
*/
SELECT @@VERSION
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
	Add a new column with a default value
*/
ALTER TABLE dbo.Client
  ADD JobTitle VARCHAR(50) NOT NULL CONSTRAINT DF_JobTitle DEFAULT ('N/D')
GO


/*
	Check the metadata!
	Any differences?
*/
SELECT 
	p.index_id, 
	p.partition_number, 
	pc.leaf_null_bit,
	coalesce(cx.name, c.name) as column_name,
	pc.partition_column_id,
	pc.modified_count,
	pc.is_nullable,
	pc.has_default,
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
	This (undocumented) command list all the pages that are allocated to an index. 
*/ 
DBCC IND ('XRaying', 'dbo.Client', 1);
GO


/*
	Check the content of a page
*/
DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 124712, 3);
GO



/*
	Insert some more records (5M)
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
	SELECT TOP (5000000) 'Charles', '1981-04-17'
	  FROM Nums
GO

/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO

/*
	Drop and add a new column with a default value
	While adding run sp_WhoIsActive
*/
ALTER TABLE dbo.Client
DROP CONSTRAINT DF_JobTitle
GO

ALTER TABLE dbo.Client
 DROP COLUMN JobTitle
GO


ALTER TABLE dbo.Client
  ADD JobTitle VARCHAR(50) NOT NULL CONSTRAINT DF_JobTitle DEFAULT ('N/D')
GO


/*
	Be sure you want to add it this way due to locking (offline operation)

	An alternative way (also used before 2012 - even for Enterprise) is:
		- add the column allowing nulls
		- update the records to a desired value in batches (minimize locking)
		- change the column to NOT NULL and add the default constraint 
*/