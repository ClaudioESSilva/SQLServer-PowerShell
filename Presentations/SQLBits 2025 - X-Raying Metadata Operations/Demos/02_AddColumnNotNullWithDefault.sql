/********************************************************************************
	DEMO: Adding column that DOESN'T allow NULLs (with a default value)

	Spoiler: This is still an "online" operation when using Enterprise edition
			 With Standard is an offline and writing operation
********************************************************************************/
/* Just don't run everything */
RAISERROR('Hey! Just don''t run everything. 😁', 20, 1) WITH LOG, NOWAIT;
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
	But then, how the engine knows what is the column default?
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
DBCC PAGE (N'XRaying', 1, 4056, 3);
GO


/*
	Show the differences on Standard Edition
*/



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
	This is cool, right?
*/



































/*
	However...
*/


















/*
	Doesn't work with all 'defaults'!

	A couple of examples:
		Work with:
			- 'A constant string'
			- GETUTCDATE()

		DOESN'T work with:
			- NEWID() 
			- NEWSEQUENTIALID()

	It only works with a:
		"runtime constant which is an expression that produces the 
		same value at runtime for each row in the table despite its determinism".

	Otherwise, it will be an OFFLINE that requires and SCH-M lock for the duration
	of the operation!

	Source: https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-table-transact-sql?view=sql-server-ver15#adding-not-null-columns-as-an-online-operation
*/


/*
	Add a new column with default value that is a "runtime constant"
*/
ALTER TABLE dbo.Client
  ADD UpdatedOn DATETIME2(3) NOT NULL CONSTRAINT DF_UpdatedOn DEFAULT (GETUTCDATE())
GO

ALTER TABLE dbo.Client
  ADD UpdatedBy VARCHAR(30) NOT NULL CONSTRAINT DF_UpdatedBy DEFAULT ('Update Script')
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
DBCC PAGE (N'XRaying', 1, 4056, 3);
GO



/*
	Now, let's add a column with a default that can't be added "online"
	Run sp_WhoIsActive while this is running
*/
ALTER TABLE dbo.Client
  ADD UUID UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_UUID DEFAULT (NEWID())
GO


/*
	Check the content of a page
	Show what happened!
*/
DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 4056, 3);
GO








/*
	Not only it was a writing operation as all the other defaults
	were written to the page as well!
*/