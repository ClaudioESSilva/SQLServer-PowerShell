/*****************************************************************************************************
******************************************************************************************************
	This 00_Setup.sql will create:
		1 - A database called "CollationsPerformance"
		2 - A "SQLCollation" schema and two tables on that schema
		3 - A "NonSQLCollation" schema and two tables on that schema
		4 - Generate and insert data on the "SQLCollation" tables
		5 - Insert the same data generated on point 4 on the "NonSQLCollation" tables
		6 - Run a query on each schema to check that data is retrieved

	You don't need to adjust anything before running this script.
	But you can if you want more data :D

	NOTE: This needs at least SQL Server 2022 
		  (due to the usage of GENERATE_SERIES function)
*******************************************************************************************************
******************************************************************************************************/
SET NOCOUNT ON

USE master
GO
ALTER DATABASE [CollationsPerformance] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE IF EXISTS CollationsPerformance
GO
CREATE DATABASE CollationsPerformance
GO

USE CollationsPerformance
GO

/********************
	Create Schema
********************/
CREATE SCHEMA [SQLCollation]
GO

/*********************
	Create 2 tables
*********************/
DROP TABLE IF EXISTS [SQLCollation].[batchref_parent]
GO
CREATE TABLE [SQLCollation].[batchref_parent](
	[batchref_parent] [char](66) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[batchref] [bigint] NULL,
	[load_date] [datetime] NULL,
	[create_time] [datetime] NULL
) ON [PRIMARY]
GO

DROP TABLE IF EXISTS [SQLCollation].[batchref_child]
GO
CREATE TABLE [SQLCollation].[batchref_child]
(
	[batchref_child] [char](66) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[batchref_parent] [char](66) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[load_date] [datetime] NULL,
	[create_time] [datetime] NULL,
CONSTRAINT [batchref_child_idx_PK] PRIMARY KEY NONCLUSTERED 
(
	[batchref_child] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


/********************
	Create Schema
********************/
CREATE SCHEMA [NonSQLCollation]
GO

/*********************
	Create 2 tables
*********************/
DROP TABLE IF EXISTS [NonSQLCollation].[batchref_parent]
GO
CREATE TABLE [NonSQLCollation].[batchref_parent](
	[batchref_parent] [char](66) COLLATE Latin1_General_CI_AS NOT NULL,
	[batchref] [bigint] NULL,
	[load_date] [datetime] NULL,
	[create_time] [datetime] NULL
) ON [PRIMARY]
GO


DROP TABLE IF EXISTS [NonSQLCollation].[batchref_child]
GO
CREATE TABLE [NonSQLCollation].[batchref_child]
(
	[batchref_child] [char](66) COLLATE Latin1_General_CI_AS NOT NULL,
	[batchref_parent] [char](66) COLLATE Latin1_General_CI_AS NOT NULL,
	[load_date] [datetime] NULL,
	[create_time] [datetime] NULL,
CONSTRAINT [batchref_child_idx_PK] PRIMARY KEY NONCLUSTERED 
(
	[batchref_child] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


/******************************
	Generate some data
******************************/
DECLARE @datalen int = 66
; WITH CTE AS 
(
    SELECT CONVERT(VARCHAR(2000), CRYPT_GEN_RANDOM(@datalen/2), 2) AS datacol
    FROM   GENERATE_SERIES(1, 800) -- Change if you want more/less record
)
INSERT [SQLCollation].[batchref_parent]([batchref_parent], [batchref], [load_date], [create_time])
SELECT datacol, 
		ABS(CheckSUM(NEWID()) / 10), 
		DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2019-09-01'), 
		DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2019-09-01')
FROM   CTE
GO


DECLARE @datalen int = 66
; WITH CTE AS 
(
    SELECT CONVERT(VARCHAR(2000), CRYPT_GEN_RANDOM(@datalen/2), 2) AS datacol
    FROM   GENERATE_SERIES(1, 2000)
)
INSERT [SQLCollation].[batchref_child]([batchref_child], [batchref_parent], [load_date], [create_time])
SELECT 
		datacol, 
		CJ.[batchref_parent],
		DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2019-09-01'), 
		DATEADD(dd, ABS(CheckSUM(NEWID()) / 10000000)+360, '2019-09-01')
FROM   CTE
	CROSS APPLY (
		SELECT TOP 1 [batchref_parent] 
		  FROM [SQLCollation].[batchref_parent] AS bp
		ORDER BY CheckSUM(NEWID())
	) CJ
GO 2000


/*
sp_help '[SQLCollation].[batchref_parent]'
sp_help '[SQLCollation].[batchref_child]'

EXEC sp_spaceused '[SQLCollation].[batchref_parent]'
EXEC sp_spaceused '[SQLCollation].[batchref_child]'
*/





/****************************************
		Insert same data on the 
		Non SQL Collation tables
****************************************/
INSERT INTO [NonSQLCollation].[batchref_parent] (batchref_parent, batchref, load_date, create_time)
SELECT batchref_parent, batchref, load_date, create_time
FROM [SQLCollation].[batchref_parent]
GO


INSERT INTO [NonSQLCollation].[batchref_child] ([batchref_child], [batchref_parent], [load_date], [create_time])
SELECT [batchref_child], [batchref_parent], [load_date], [create_time]
FROM [SQLCollation].[batchref_child]
GO




/***********************************
	Check that data is retrieved
***********************************/
SELECT c.batchref_parent
	,MAX(p.batchref) AS LatestBatch
FROM [NonSQLCollation].[batchref_child] AS c
	INNER JOIN [NonSQLCollation].[batchref_parent] AS p
	   ON c.batchref_parent = p.batchref_parent
GROUP BY c.batchref_parent
GO

SELECT c.batchref_parent
	,MAX(p.batchref) AS LatestBatch
FROM [SQLCollation].[batchref_child] AS c
	INNER JOIN [SQLCollation].[batchref_parent] AS p
	   ON c.batchref_parent = p.batchref_parent
GROUP BY c.batchref_parent
GO