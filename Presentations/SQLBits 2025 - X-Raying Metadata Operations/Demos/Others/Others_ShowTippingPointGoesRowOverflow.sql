/*
	Showing the tipping point for a variable-length that goes "Row-Overflow"
*/

DROP TABLE IF EXISTS dbo.VariableLengthPointer
GO

CREATE TABLE dbo.VariableLengthPointer 
(
	Id			int			NOT NULL IDENTITY(1,1) PRIMARY KEY,
	FirstName	varchar(30) NULL,
	DoB			date		NULL,
	JobTitle	varchar(30) NULL,
	Bio			char(7988)	NULL
);
GO


/*
	More than enough space
*/
INSERT INTO dbo.VariableLengthPointer (FirstName, DoB, JobTitle, Bio) 
VALUES (REPLICATE('N', 15), '1990-01-01', REPLICATE('N', 15), 'Hello, I''m Nuno')
GO

/*
	Check the record size
*/
DBCC IND ('XRaying', 'dbo.VariableLengthPointer', 1);
GO

DBCC TRACEON (3604);
GO
DBCC PAGE (N'XRaying', 1, 1583848, 3);
GO


/*
	The maximum?
*/
INSERT INTO dbo.VariableLengthPointer (FirstName, DoB, JobTitle, Bio) 
VALUES (REPLICATE('M', 26), '1990-01-01', REPLICATE('M', 26), 'Hello, I''m Maria')
GO

/*
	Check the record size
*/
DBCC IND ('XRaying', 'dbo.VariableLengthPointer', 1);
GO

DBCC PAGE (N'XRaying', 1, 1583850, 3);
GO


/*
	Then this will give an error? or...
*/
INSERT INTO dbo.VariableLengthPointer (FirstName, DoB, JobTitle, Bio) 
VALUES (REPLICATE('Z', 27), '1990-01-01', REPLICATE('I', 26), 'Hello, I''m Zita')
GO


/*
	Check what happened
*/
DBCC IND ('XRaying', 'dbo.VariableLengthPointer', 1);
GO

DBCC PAGE (N'XRaying', 1, 1583851, 3);
GO

/*
	Show new allocations
*/
DBCC IND ('XRaying', 'dbo.VariableLengthPointer', 1);
GO


