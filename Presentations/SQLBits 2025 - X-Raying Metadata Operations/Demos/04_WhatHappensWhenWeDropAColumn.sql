/********************************************************************************
	DEMO: What happens when we drop a column on a SQL Server table? Where's my space?

	Blog post: https://claudioessilva.eu/2024/05/29/What-happens-when-we-drop-a-column-on-a-SQL-Server-table-Wheres-my-space/

	Spoiler: The record/table size will remain unchanged.
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
	This (undocumented) command list all the pages that are allocated to an index. 
*/ 
DBCC IND ('XRaying', 'dbo.Client', 1);
GO

/*
	A newer way (DMF) with a bit more information (also undocumented)
*/
SELECT *
  FROM sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID(N'dbo.Client'), NULL, NULL, N'DETAILED')
-- WHERE page_type_desc = 'DATA_PAGE'
GO

/*
	Check the content of a page

	TF 3604 - Make the output go to the console (instead of error log)

	printopt = 3 means we will get the page header plus detailed per-row interpretation
*/
DBCC TRACEON (3604);
GO
DBCC PAGE ('XRaying', 1, 511768, 3);
GO


/**********************************************************************************************************************
	There is also a DMF that can return some of the information about a page in the database. 
	If we are using SQL Server 2019 or a later version the sys.dm_db_page_info DMF gives you page header information 
	(but not the contents/records within the page). 
	This one is documented and is currently supported! 
	Check it here: https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-page-info-transact-sql
**********************************************************************************************************************/
SELECT *
  FROM sys.dm_db_page_info (DB_ID(), 1, 511768, DEFAULT);
GO

/*
	Let's drop our DoB column
*/
ALTER TABLE Client
 DROP COLUMN DoB
GO

/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO

/*
	Still the same as before!
*/


/*
	Let’s dump the content of the same page again to check what changed.
*/
DBCC TRACEON (3604);
GO
DBCC PAGE ('XRaying', 1, 511768, 3);
GO



/**********************************************************************************************************************
	Dropping a column is a metadata/logical operation not a physical one.
	We need to rebuild the table to reclaim the space.

	Note/curiosity: 
		When it is a record that is deleted, the data isn't removed/overwritten by the delete action (record is marked
		as GHOST_DATA_RECORD).
		
		Paul Randal mentions here (https://www.sqlskills.com/blogs/paul/inside-the-storage-engine-anatomy-of-a-page/):
			“the cost of that will be deferred for the inserters and not for the deleters”.
**********************************************************************************************************************/


















/*
	How can we reclaim the space?
	
	Let's clear the dropped column and tidy up things by REBUILD it
*/
ALTER TABLE Client REBUILD 
GO

/*
	Check what is allocated to this object
*/
EXEC sp_spaceused 'dbo.Client'
GO

/*
	EASY RIGHT?!

	In this case yes!

	But let's stop and think a bit about this before running it:
		- Does this means I need to plan downtime? ("it depends")
		- Standard vs Enterprise
			- ONLINE / RESUMABLE
*/
