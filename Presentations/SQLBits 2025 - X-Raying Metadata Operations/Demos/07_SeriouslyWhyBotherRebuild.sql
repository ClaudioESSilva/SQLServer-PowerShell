/********************************************************************************
	DEMO: Seriously, why bother rebuilding?

	Spoiler: Dropping a column won't reduce record size
			 Inserts will still have the waste
			 Updates won't re-use the space
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
	Check the 'AverageRecordSize'
*/
DBCC SHOWCONTIG('dbo.Client') WITH TABLERESULTS
GO

/*
	Let's drop our DoB column
*/
ALTER TABLE Client
 DROP COLUMN DoB
GO

/*
	Check the 'AverageRecordSize' again
*/
DBCC SHOWCONTIG('dbo.Client') WITH TABLERESULTS
GO



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
  INSERT INTO dbo.Client ([FirstName])
  SELECT TOP (50000) 'Alex'
    FROM Nums
GO

/*
	Check the 'AverageRecordSize' again. No changes
*/
DBCC SHOWCONTIG('dbo.Client') WITH TABLERESULTS
GO

/*
	Get latest data page and check the content.
*/
SELECT *
  FROM sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID(N'dbo.Client'), NULL, NULL, N'DETAILED')
GO

/*
	Check the content of a page

	TF 3604 - Make the output go to the console (instead of error log)

	printopt = 3 means we will get the page header plus detailed per-row interpretation
*/
DBCC TRACEON (3604);
GO
DBCC PAGE ('XRaying', 1, 1517238, 3);
GO

/*
	Update a record and check it still contains the dropped column
*/
UPDATE dbo.Client
   SET FirstName = 'My new name'
 WHERE Id = 99883
GO