/********************************************************************************
	DEMO: Add/remove columns multiple times (and not rebuilding) will fail
		  at some point
********************************************************************************/

/* Just don't run everything */
RAISERROR('Hey! Just don''t run everything. 😁', 20, 1) WITH LOG, NOWAIT;
GO

USE XRaying
GO

DROP TABLE IF EXISTS dbo.Client
GO

CREATE TABLE dbo.Client
(
	Id			int			NOT NULL IDENTITY(1,1) PRIMARY KEY,
	FirstName	varchar(30)	NULL,
	JobTitle	varchar(30)	NULL,
	Bio			nchar(3500)	NULL,
	DoB			date		NULL
);
GO

INSERT INTO dbo.Client (FirstName, DoB, JobTitle, Bio) 
VALUES (REPLICATE('A', 30), '1990-01-01', REPLICATE('A', 30), 'Hello, I''m Alex')
GO

ALTER TABLE dbo.Client
 DROP COLUMN Bio
GO

ALTER TABLE dbo.Client 
  ADD NewColumn nchar(300)
GO


DBCC SHOWCONTIG('dbo.Client') WITH TABLERESULTS
GO

/* Will fail */
ALTER TABLE dbo.Client 
  ADD NewColumn2 nchar(300)
GO


DBCC IND ('XRaying', 'dbo.Client', 1);
GO

DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 1177640, 3);
GO

/*
	Check the metadata
*/
SELECT  sc.name, 
		sipc.leaf_offset, 
		sipc.max_inrow_length,
		sipc.is_dropped
  FROM sys.partitions sp
	LEFT JOIN sys.system_internals_partition_columns sipc 
	  ON sp.partition_id = sipc.partition_id
	LEFT JOIN sys.columns sc 
	  ON sc.column_id = sipc.partition_column_id AND sc.OBJECT_ID = sp.OBJECT_ID
 WHERE sp.OBJECT_ID = OBJECT_ID('dbo.Client')
GO



/*
	Clean the wasted space
*/
ALTER TABLE dbo.Client REBUILD 
GO


SELECT  sc.name, 
		sipc.leaf_offset, 
		sipc.max_inrow_length,
		sipc.is_dropped
  FROM sys.partitions sp
	LEFT JOIN sys.system_internals_partition_columns sipc 
	  ON sp.partition_id = sipc.partition_id
	LEFT JOIN sys.columns sc 
	  ON sc.column_id = sipc.partition_column_id AND sc.OBJECT_ID = sp.OBJECT_ID
 WHERE sp.OBJECT_ID = OBJECT_ID('dbo.Client')
GO

/* 
	Won't fail 
*/
ALTER TABLE dbo.Client 
  ADD NewColumn2 nchar(300)
GO




/*
	BUT...
	If the column is the last, this problem won't happen.
*/
DROP TABLE IF EXISTS dbo.ClientDiffColOrder
GO

CREATE TABLE dbo.ClientDiffColOrder
(
	Id			int			NOT NULL IDENTITY(1,1) PRIMARY KEY,
	FirstName	varchar(30)	NULL,
	JobTitle	varchar(30)	NULL,
	DoB			date		NULL,
	Bio			nchar(3500)	NULL
);
GO

INSERT INTO dbo.ClientDiffColOrder (FirstName, DoB, JobTitle, Bio) 
VALUES (REPLICATE('A', 30), '1990-01-01', REPLICATE('A', 30), 'Hello, I''m Alex')
GO


ALTER TABLE dbo.ClientDiffColOrder
 DROP COLUMN Bio
GO


SELECT  sc.name, 
		sipc.leaf_offset, 
		sipc.max_inrow_length,
		sipc.is_dropped
  FROM sys.partitions sp
	LEFT JOIN sys.system_internals_partition_columns sipc 
	  ON sp.partition_id = sipc.partition_id
	LEFT JOIN sys.columns sc 
	  ON sc.column_id = sipc.partition_column_id AND sc.OBJECT_ID = sp.OBJECT_ID
 WHERE sp.OBJECT_ID = OBJECT_ID('dbo.ClientDiffColOrder')
GO



ALTER TABLE dbo.ClientDiffColOrder 
  ADD NewColumn nchar(300)
GO

/*
	This failed before
*/
ALTER TABLE dbo.ClientDiffColOrder 
  ADD NewColumn2 nchar(300)
GO



SELECT  sc.name, 
		sipc.leaf_offset, 
		sipc.max_inrow_length,
		sipc.is_dropped
  FROM sys.partitions sp
	LEFT JOIN sys.system_internals_partition_columns sipc 
	  ON sp.partition_id = sipc.partition_id
	LEFT JOIN sys.columns sc 
	  ON sc.column_id = sipc.partition_column_id AND sc.OBJECT_ID = sp.OBJECT_ID
 WHERE sp.OBJECT_ID = OBJECT_ID('dbo.Client')
GO



DBCC IND ('XRaying', 'dbo.ClientDiffColOrder', 1);
GO

DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 1193834, 3);
GO

INSERT INTO dbo.ClientDiffColOrder (FirstName, DoB, JobTitle, NewColumn, NewColumn2) 
VALUES (REPLICATE('A', 30), '1990-01-01', REPLICATE('A', 30), 'Hello, I''m Alex New', 'Hello, I''m Alex New 2')
GO