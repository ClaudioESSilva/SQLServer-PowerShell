/* 
	As a curiosity:
		Show maximum number of records on a table (if it's an smallint)

		NOTE: 8060 is the max record size. 
			  It is different from the max data on a page which is 8096
*/

DROP TABLE IF EXISTS dbo.MaxRecords
GO

CREATE TABLE dbo.MaxRecords 
(
	Id			smallint	IDENTITY(1,1) PRIMARY KEY
);
GO

INSERT INTO dbo.MaxRecords
DEFAULT VALUES
GO 737

DBCC IND ('XRaying', 'dbo.MaxRecords', 1);
GO

/*
	Show the lenght of the record (9)
*/
DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 1536721, 3);
GO


/* 
	11 because it's 9 + 2 per record 
*/
SELECT 736 * 11
/* 8096 */


