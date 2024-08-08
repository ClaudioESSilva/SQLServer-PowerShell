/*
	"8060 before or after compression?!"
	


	Source: https://learn.microsoft.com/en-us/sql/relational-databases/data-compression/data-compression

	A table can't be enabled for compression when the maximum row size plus 
	the compression overhead exceeds the maximum row size of 8,060 bytes. 
	For example, a table that has the columns c1 CHAR(8000) and c2 CHAR(53) 
	can't be compressed because of the additional compression overhead. 
	When the vardecimal storage format is used, the row-size check is performed 
	when the format is enabled. For row and page compression, the row-size 
	check is performed when the object is initially compressed, and then 
	checked as each row is inserted or modified. 
	
	Compression enforces the following two rules:
		1. An update to a fixed-length type must always succeed.
		2. Disabling data compression must always succeed. 
		   Even if the compressed row fits on the page, which means that it's 
		   less than 8,060 bytes; SQL Server prevents updates that don't fit 
		   on the row when it's uncompressed.
*/
USE XRaying
GO

DROP TABLE IF EXISTS dbo.Client
GO

CREATE TABLE dbo.Client 
(
	c1 CHAR(8000),
	c2 CHAR(48)
);
GO

INSERT INTO dbo.Client (c1, c2)
VALUES (REPLICATE('A', 8000), REPLICATE('B', 48))

INSERT INTO dbo.Client (c1, c2)
VALUES (REPLICATE('A', 7000), REPLICATE('B', 48))



CREATE TABLE dbo.Client 
(
	Id			int			NOT NULL IDENTITY(1,1) PRIMARY KEY,
	FirstName	varchar(19) NULL,
	DoB			date		NULL,
	JobTitle	varchar(36) NULL,
	Bio			nchar(3990)	NULL,
	Bio2		nchar(6)	NULL
);
GO

ALTER TABLE dbo.Client REBUILD
WITH (DATA_COMPRESSION = PAGE)
GO

/*
	If 2x then 8096
*/
INSERT INTO dbo.Client (FirstName, DoB, JobTitle, Bio, Bio2) 
VALUES (REPLICATE('A', 19), '1990-01-01', REPLICATE('A', 30), REPLICATE('A', 3970), REPLICATE('A', 6))
GO


DBCC IND ('XRaying', 'dbo.Client', 1);
GO

DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 1197488, 3);
GO


ALTER TABLE dbo.Client REBUILD
WITH (DATA_COMPRESSION = NONE)