/********************************************************************************
	DEMO: Can't I just use DBCC CLEANTABLE?

	DBCC CLEANTABLE: https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-cleantable-transact-sql

	Spoiler: If the column(s) dropped were a variable-length - YES!
			 But it will only clear space on the page itself!
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
  Id		int NOT NULL identity(1,1),
  FirstName varchar(50),
  DoB		date
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
  SELECT TOP (5000000) 'Alex', '1900-01-01'
    FROM Nums
GO


/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO

/*
	Check the page_count and avg_page_space_used_in_percent
*/
SELECT alloc_unit_type_desc,
    page_count,
    avg_page_space_used_in_percent,
    record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.Client'), NULL, NULL, 'Detailed');
GO


/*
	DROP HERE FOR COMPARISON

		name	rows		reserved	data		index_size	unused
1st		
2nd		
3rd		

		alloc_unit_type_desc	page_count	avg_page_space_used_in_percent	record_count
1st		
2nd		
3rd		

*/


/*
	Let's drop our FirstName column
*/
ALTER TABLE Client
 DROP COLUMN FirstName
GO



/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO



SELECT alloc_unit_type_desc,
    page_count,
    avg_page_space_used_in_percent,
    record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.Client'), NULL, NULL, 'Detailed');
GO


/*
	Run DBCC CLEANTABLE

	NOTES: 
		- You can specify a "batch_size" (default is 1000). 
		  Be aware of the length of a single transaction

		- It's a blocking operation.

		- This is fully logged. 
		  Therefore be aware of log growth.

		- Shouldn't be executed as a routine maintenance task!
*/
DBCC CLEANTABLE (XRaying, 'dbo.Client');
GO



/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO



SELECT alloc_unit_type_desc,
    page_count,
    avg_page_space_used_in_percent,
    record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.Client'), NULL, NULL, 'Detailed');
GO



/*	
	No difference on the number of pages? - Correct. It only clean the space on the page.
*/
/*
	This (undocumented) command list all the pages that are allocated to an index. 
*/ 
DBCC IND ('XRaying', 'dbo.Client', 1);
GO

/*
	Let’s dump the content of the same page again to check what changed.
*/
DBCC TRACEON (3604);
GO
DBCC PAGE ('XRaying', 1, 517633, 3);
GO


/*
	As we haven't rebuild the table, the metadata still exists
*/
