/********************************************************************************
	DEMO: Identify Tables With Dropped Columns

	Blog post: https://claudioessilva.eu/2024/07/09/Identify-Tables-With-Dropped-Columns/

	Spoiler: We can use some metadata system views
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
  DoB		date
)
GO

/*
	Insert some records	
*/
INSERT INTO dbo.Client (FirstName, DoB)
SELECT 'Alex', '1990-01-03'
UNION
SELECT 'Bart', '1993-03-13'
UNION
SELECT 'Charles', '1981-04-17'
GO


/*
	DROP a column	
*/
ALTER TABLE Client
 DROP COLUMN DoB
GO


/*
	A newer way (DMF) with a bit more information (also undocumented)
*/
SELECT  object_name(object_id) as TableName, 
		allocated_page_page_id
  FROM sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID(N'dbo.Client'), NULL, NULL, N'DETAILED')
 WHERE page_type_desc = 'DATA_PAGE'
GO


/*
	Check the content of a page

	TF 3604 - Make the output go to the console (instead of error log)

	printopt = 3 means we will get the page header plus detailed per-row interpretation

	WITH TABLERESULTS - Shows the output in a table format
*/
DBCC TRACEON (3604);
GO
DBCC PAGE ('XRaying', 1, 1583840, 3) WITH TABLERESULTS;
GO




/*
	Just one to get the idea
*/
IF OBJECT_ID('tempdb..#DBCCPAGE') IS NOT NULL 
	DROP TABLE #DBCCPAGE;
GO
CREATE TABLE #DBCCPAGE (
    [ParentObject]  VARCHAR(255),
    [Object]        VARCHAR(255),
    [Field]         VARCHAR(255),
    [Value]         VARCHAR(255)
);

INSERT INTO #DBCCPAGE
EXECUTE ('DBCC PAGE (''Xraying'', 1, 1583840, 3) WITH TABLERESULTS;');

SELECT *
  FROM #DBCCPAGE
WHERE Field = 'DROPPED'

/*
	  This was an example just for one table...
	  You could (please, don't do it!) create some more code 
	to dynamically check other tables.

	  But there is a better way...
*/






















/*
	But first...
	Recreate the table and insert the records!
*/
DROP TABLE IF EXISTS dbo.Client
GO

/* 
	Create a table 
*/
CREATE TABLE dbo.Client
(
  Id		int NOT NULL identity(1,1),
  FirstName varchar(50),
  DoB		date
)
GO

/*
	Insert some records	
*/
INSERT INTO dbo.Client (FirstName, DoB)
SELECT 'Alex', '1990-01-03'
UNION
SELECT 'Bart', '1993-03-13'
UNION
SELECT 'Charles', '1981-04-17'
GO


























/*
	Enter some metadata system views!
		- sys.system_internals_partitions 
		- sys.system_internals_partition_columns
*/
SELECT *
 FROM sys.system_internals_partitions p
	JOIN sys.system_internals_partition_columns pc
	  ON p.partition_id = pc.partition_id
 WHERE p.object_id = OBJECT_ID('dbo.Client')
GO









/*
	Get fewer columns
*/
SELECT  object_schema_name(p.object_id) table_schema_name,
		object_name(p.object_id) table_name,
		c.[name] as column_name,
		pc.partition_column_id,
		pc.is_dropped
 FROM sys.system_internals_partitions p
	JOIN sys.system_internals_partition_columns pc
	  ON p.partition_id = pc.partition_id
	LEFT JOIN sys.columns c
  	  ON p.object_id = c.object_id
	 AND pc.partition_column_id = c.column_id
 WHERE p.object_id = OBJECT_ID('dbo.Client')
GO


/*
	DROP a column	
*/
ALTER TABLE Client
 DROP COLUMN DoB
GO


SELECT  
		object_schema_name(p.object_id) table_schema_name,
		object_name(p.object_id) table_name,
		c.[name] as column_name,
    	pc.partition_column_id,
		pc.is_dropped
  FROM sys.system_internals_partitions p
	JOIN sys.system_internals_partition_columns pc
	  ON p.partition_id = pc.partition_id
	LEFT JOIN sys.columns c
	  ON p.object_id = c.object_id
	 AND pc.partition_column_id = c.column_id
 WHERE p.object_id = OBJECT_ID('dbo.Client')
   AND pc.is_dropped = 1
GO

/*
	NOTE: With this query, if you have dropped columns on a partitioned table, 
	you will get a record for each existing partition of that same table.
*/



/*
	To check what can be the output if we have more than one table with 
	dropped columns let's create a second table
*/
DROP TABLE IF EXISTS dbo.MemoryGrant
GO

CREATE TABLE dbo.MemoryGrant
(
	id				int PRIMARY KEY IDENTITY(1,1) NOT NULL ,
	number			int NULL,
	description500	varchar(500) NULL,
	description4000	varchar(4000) NULL,
	descriptionMAX	varchar(max) NULL
)
GO

ALTER TABLE dbo.MemoryGrant
 DROP COLUMN description4000
GO


/*
	Check that we can find more than one table with dropped columns
*/
SELECT  
		object_schema_name(p.object_id) table_schema_name,
		object_name(p.object_id) table_name,
		c.[name] as column_name,
    	pc.partition_column_id,
		pc.is_dropped
  FROM sys.system_internals_partitions p
	JOIN sys.system_internals_partition_columns pc
	  ON p.partition_id = pc.partition_id
	LEFT JOIN sys.columns c
	  ON p.object_id = c.object_id
	 AND pc.partition_column_id = c.column_id
 WHERE pc.is_dropped = 1
GO

