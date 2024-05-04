/*
	This demo shows the impact of the data types and sizes on:
		- data size (also think backups/restores, environment refreshes)
		- indexes sizes
*/
USE DataTypes
GO

DROP TABLE IF EXISTS ExcessiveDataTypesAndSizes
GO

CREATE TABLE ExcessiveDataTypesAndSizes
(
	ID		bigint NOT NULL PRIMARY KEY IDENTITY(1, 1), -- 8 bytes
	UUID	nvarchar(50), -- 100 bytes (max)
	DoB		datetime -- 8 bytes
)
GO

/*
	On average, each record will have 8 + 72 + 8 = 88 bytes ?? (just for the values)
	UUID will save an NEWID(), which is a GUID, that contains 36 chars and as unicode field that is 72 bytes
*/
/*
	Check an example of a GUID value
*/
SELECT NEWID()


/* 
	Inserting 10M rows
	~10 seconds
*/
INSERT INTO ExcessiveDataTypesAndSizes (UUID, DoB)
SELECT TOP (10000000) NEWID(), DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+30, '2024-01-02')
FROM sys.columns AS a, sys.columns AS b, sys.columns AS c, sys.columns AS d
GO

SELECT TOP 10 * 
FROM ExcessiveDataTypesAndSizes
GO

-- Table size
sp_spaceused ExcessiveDataTypesAndSizes
GO



DROP TABLE IF EXISTS LessExcessiveDataTypesAndSizes
GO

CREATE TABLE LessExcessiveDataTypesAndSizes
(
	ID		INT NOT NULL PRIMARY KEY IDENTITY(1, 1), -- 4 bytes
	UUID	VARCHAR(36), -- 36 bytes (max)
	DoB		DATETIME2(0) -- 6 bytes
)
GO

/*
	On average, each record will have 4 + 36 + 6 = 46 bytes ?? (just for the values)
*/


-- Turn off Identity on the table so we can copy and have exactly the same records
SET IDENTITY_INSERT LessExcessiveDataTypesAndSizes ON
GO

/*
	~10 sec
*/
INSERT INTO LessExcessiveDataTypesAndSizes WITH(TABLOCKX) (ID, UUID, DoB)
SELECT ID, UUID, DoB
FROM ExcessiveDataTypesAndSizes
GO

SET IDENTITY_INSERT LessExcessiveDataTypesAndSizes OFF
GO

SELECT TOP 10 * 
FROM LessExcessiveDataTypesAndSizes
GO

-- Table size
sp_spaceused LessExcessiveDataTypesAndSizes
GO




-- Create new table with modest data types and sizes
DROP TABLE IF EXISTS BetterDataTypesAndSizes
GO

CREATE TABLE BetterDataTypesAndSizes
(
	ID		INT NOT NULL PRIMARY KEY IDENTITY(1, 1), -- 4 bytes
	UUID	UNIQUEIDENTIFIER, -- 16 bytes
	DoB		DATE -- 3 bytes
)
GO

/*
	On average, each record will have 4 + 16 + 3 = 23 bytes (just for the values)
*/

-- Turn off Identity on the table so we can copy and have exactly the same records
SET IDENTITY_INSERT BetterDataTypesAndSizes ON
GO

/*
	~8 sec
*/
INSERT INTO BetterDataTypesAndSizes WITH(TABLOCKX) (ID, UUID, DoB)
SELECT ID, UUID, DoB
FROM ExcessiveDataTypesAndSizes
GO

SET IDENTITY_INSERT BetterDataTypesAndSizes OFF
GO


-- Check data
SELECT TOP 10 * 
FROM BetterDataTypesAndSizes
GO

-- Table size
sp_spaceused BetterDataTypesAndSizes
GO



-- Compare both data
SELECT TOP 10 * 
FROM ExcessiveDataTypesAndSizes
ORDER BY ID
GO

SELECT TOP 10 * 
FROM LessExcessiveDataTypesAndSizes
ORDER BY ID
GO 

SELECT TOP 10 * 
FROM BetterDataTypesAndSizes
ORDER BY ID
GO


/*
	Compare space
*/
sp_spaceused ExcessiveDataTypesAndSizes
GO
sp_spaceused LessExcessiveDataTypesAndSizes
GO
sp_spaceused BetterDataTypesAndSizes
GO


-- SET STATISTICS TIME, IO ON
CREATE NONCLUSTERED INDEX NCI_ExcessiveDataTypesAndSizes_DoB ON ExcessiveDataTypesAndSizes (DoB)
GO

CREATE NONCLUSTERED INDEX NCI_LessExcessiveDataTypesAndSizes_DoB ON LessExcessiveDataTypesAndSizes (DoB)
GO

CREATE NONCLUSTERED INDEX NCI_BetterDataTypesAndSizes_DoB ON BetterDataTypesAndSizes (DoB)
GO


/*
	Check space
*/
sp_spaceused ExcessiveDataTypesAndSizes
GO
sp_spaceused LessExcessiveDataTypesAndSizes
GO
sp_spaceused BetterDataTypesAndSizes
GO



/*
	CREATE NCI on UUID column
*/
CREATE NONCLUSTERED INDEX NCI_ExcessiveDataTypesAndSizes_UUID ON ExcessiveDataTypesAndSizes (UUID)
GO

CREATE NONCLUSTERED INDEX NCI_LessExcessiveDataTypesAndSizes_UUID ON LessExcessiveDataTypesAndSizes (UUID)
GO

CREATE NONCLUSTERED INDEX NCI_BetterDataTypesAndSizes_UUID ON BetterDataTypesAndSizes (UUID)
GO



/*
	Check space
*/
sp_spaceused ExcessiveDataTypesAndSizes
GO
sp_spaceused LessExcessiveDataTypesAndSizes
GO
sp_spaceused BetterDataTypesAndSizes
GO


/*
	This was on a table with 3 columns ??
	Now imagine this on a wider table with some more records!


	Also:
		- You can't create indexes on (n)varchar(MAX) columns
*/